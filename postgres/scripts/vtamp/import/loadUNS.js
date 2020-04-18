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
console.log(`path: ${_filePath}  appid: ${_appId}  apptableid: ${_appTableId}`);
// const _mlsId = Number(process.argv[5]);
// const _complianceId = Number(process.argv[6]);
// const _mlsTypes = {};
// const _complianceTypes = {};
// console.log(`path: ${_filePath}  appId: ${_appId}  apptableId: ${_appTableId}  mlsId: ${_mlsId}  complianceId: ${_complianceId}`);

function findUns(name) {
  return new Promise((resolve) => {
    Masterdata.findOne(
      { where: {appid: _appId, apptableid: _appTableId, name: name}
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
    const elements = line.split(',');
    // console.log(`--------- cnt: ${cnt++}  elements[1]: ${elements[1]}`);
    if (elements[1] !== undefined && elements[1] !== '') {
      //console.log(`elements: ${elements.length}`);
      const name = elements[1].replace(/"/g, '');
      const descr = elements[2].replace(/"/g, '');
      const systemid = Number(elements[3]);
      const iptid = Number(elements[4]);
      const active = Boolean(elements[5]);
      const poeid = Number(elements[6]);
      findUns(name)
        .then((resp) => {
          if (resp === undefined) {
            // console.log(`****************** insert: name: ${name}`);
            Masterdata
              .build({
                appid: _appId,
                apptableid: _appTableId,
                name: name,
                description: descr,
                createdat: sequelize.fn('NOW'),
                jsondata: {
                  active: active,
                  iptid: iptid,
                  poeid: poeid,
                  systemid: systemid
                }
              })
              .save()
              .then(results => {
                console.log(`****************** insert: name: ${name}`);
                resolve();
              })
              .catch(error => {
                console.error(error);
              });
            // resolve();
          } else {
            console.log(`-- skip buno: ${name}`);
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
          // const done = 20;
          const done = lines.length;
          //===================================

          // must use javascript for loop to halt loop for await processing
          for (const line of lines) {
            if (cnt < done) {
              cnt++;
              await processLine(line);
              complete++;
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
  .then( () => {
    console.log('Connection has been established successfully.');
    processCSV(_filePath)
      .then(() => {
        sequelize.close();
      });
  })
  .catch(err => {
    console.error('Unable to connect to the database: ', err);
  });


