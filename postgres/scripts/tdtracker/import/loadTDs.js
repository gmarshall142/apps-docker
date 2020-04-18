#!/usr/bin/env node

const Sequelize = require('../../node_modules/sequelize');
const fs = require('fs');
const _ = require('lodash');

const sequelize = new Sequelize('appfactory', 'gmarshall', 'P@ssw0rd',
  {
    host: 'localhost',
    dialect: 'postgres',
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  });

const Appdata = sequelize.define('appdata', {
    appid: { type: Sequelize.INTEGER, allowNull: false },
    apptableid: { type: Sequelize.INTEGER, allowNull: true },
    jsondata: { type: Sequelize.JSON, allowNull: true },
  },
  {
    schema: 'app',
    timestamps: true,
    createdAt: 'createdat',
    updatedAt: 'updatedat',
  });


const Masterdata = sequelize.define('masterdata', {
    appid: { type: Sequelize.INTEGER, allowNull: false },
    apptableid: { type: Sequelize.INTEGER, allowNull: false },
    name: { type: Sequelize.STRING, allowNull: false },
    description: { type: Sequelize.STRING, allowNull: true },
    jsondata: { type: Sequelize.JSON, allowNull: true },
  },
  {
    schema: 'app',
    timestamps: true,
    createdAt: 'createdat',
    updatedAt: 'updatedat',
  });

const _filePath = process.argv[2];
const _appId = Number(process.argv[3]);
const _appTableId = Number(process.argv[4]);
const _mlsId = Number(process.argv[5]);
const _complianceId = Number(process.argv[6]);
const _mlsTypes = {};
const _complianceTypes = {};
console.log(`path: ${_filePath}  appId: ${_appId}  apptableId: ${_appTableId}  mlsId: ${_mlsId}  complianceId: ${_complianceId}`);

function init() {
  return new Promise( async (resolve, reject) => {
    const promises = [];
    promises[0] = Masterdata.findAll({ where: {appid: _appId, apptableid: _mlsId} });
    promises[1] = Masterdata.findAll({ where: {appid: _appId, apptableid: _complianceId} });

    try {
      const responses = await Promise.all(promises);
      // mls
      _.forEach(responses[0], it => _mlsTypes[it.dataValues.name] = it.dataValues.id);
      // compliance
      _.forEach(responses[1], it => _complianceTypes[it.dataValues.name] = it.dataValues.id);
      resolve();
    } catch (err) {
      console.log(err);
      reject(err);
    }
  });
}

function findTD(td) {
  return new Promise((resolve) => {
    Appdata.findOne({
      where: {jsondata: { td: td}}
    })
      .then(response => {
        resolve(response.dataValues);
      })
      .catch(error => {
        //console.error(error);
        resolve(undefined);
      });
  });
}

function processLine(line) {
  return new Promise((resolve) => {
    const elements = line.split('\t');
    // console.log(`--------- cnt: ${cnt++}  elements[1]: ${elements[1]}`);
    if (elements[1] !== undefined && elements[1] !== '') {
      //console.log(`elements: ${elements.length}`);
      const ecp = elements[0];
      const td = elements[1];
      const tcto = elements[2];
      const mlTmp = elements[3].replace(/"/g, '').replace(/ /g, '').split(',');
      const mls = [];
      _.forEach(mlTmp, it => mls.push(_mlsTypes[it]));
      const subject = elements[4].replace(/"/g, '');
      //console.log(`td: ${td}  tcto: ${tcto}  ecp: ${ecp}  ml: ${JSON.stringify(ml)}  subject: ${subject}`);
      findTD(td)
        .then((resp) => {
          if (resp === undefined) {
            // console.log(`****************** insert: td: ${td}  tcto: ${tcto}  ecp: ${ecp}  ml: ${JSON.stringify(mls)}  subject: ${subject}`);
            Appdata
              .build({
                appid: _appId,
                apptableid: _appTableId,
                jsondata: {
                  td: td,
                  tcto: tcto,
                  ecp: ecp,
                  mls: mls,
                  subject: subject,
                  purpose: '',
                  instructions: ''
                }
              })
              .save()
              .then(results => {
                console.log(`****************** insert: td: ${td}  tcto: ${tcto}  ecp: ${ecp}  ml: ${JSON.stringify(mls)}  subject: ${subject}`);
                resolve();
              })
              .catch(error => {
                console.error(error);
              });
          } else {
            console.log(`-- skip td: ${td}`);
            // possibly update
            resolve();
          }
        });
    } else {
      resolve();
    }
  });
}

async function processCSV(path) {
  return new Promise((resolve, reject) => {
    try {
      fs.readFile(path, 'utf8', async (err, data) => {
        if (err) {
          console.error(`error: ${err}`);
        } else {
          let cnt = 0;
          let complete = 0;
          const lines = data.split('\n');
          //===================================
          // const done = 10;
          const done = lines.length;
          //===================================

          // must use javascript for loop to halt loop for await processing
          for (const line of lines) {
            if (cnt < done) {
              cnt++;
              await processLine(line);
              complete++;
              // if (cnt === lines.length) {
              if (complete >= done) {
                resolve(); // done
              }
            }
          }
        }
      });
    } catch(err) {
      console.error(err);
      reject();
    }
  });
}

// connect to sequelize
sequelize
  .authenticate()
  .then( async () => {
    await init();
    console.log('Connection has been established successfully.');
    processCSV(_filePath)
      .then(() => {
        sequelize.close();
      });
  })
  .catch(err => {
    console.error('Unable to connect to the database: ', err);
  });


