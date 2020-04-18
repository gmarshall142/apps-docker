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

const Buno = sequelize.define('bunos', {
    identifier: { type: Sequelize.STRING, allowNull: false },
    description: { type: Sequelize.STRING, allowNull: true }
  },
  {
    schema: 'app',
    timestamps: true,
    createdAt: 'createdat',
    updatedAt: 'updatedat',
  });

const _filePath = process.argv[2];
const _appId = Number(process.argv[3]);
const _tdTableId = Number(process.argv[4]);
const _depTableId = Number(process.argv[5]);
const _bunoId = Number(process.argv[6]);
const _complianceId = Number(process.argv[7]);
const _bunos = {};
const _complianceTypes = {};
const _tdNotFound = [];
const _bunoNotFound = [];
console.log(`path: ${_filePath}  appId: ${_appId}  tdTableId: ${_tdTableId}  depTableId: ${_depTableId}  bunoId: ${_bunoId}  complianceId: ${_complianceId}`);

function init() {
  return new Promise( async (resolve, reject) => {
    const promises = [];
    promises[0] = Buno.findAll();
    promises[1] = Masterdata.findAll({ where: {appid: _appId, apptableid: _complianceId} });

    try {
      const responses = await Promise.all(promises);
      // bunos
      _.forEach(responses[0], it => _bunos[it.dataValues.identifier] = it.dataValues.id);
      // compliance
      _.forEach(responses[1], it => _complianceTypes[it.dataValues.name] = it.dataValues.id);
      resolve();
    } catch (err) {
      console.log(err);
      reject(err);
    }
  });
}

function findDependency(td, dependency) {
  return new Promise( async (resolve) => {
    const promises = [];
    promises[0] = Appdata.findOne({ where: {apptableid: _tdTableId, jsondata: { td: td}} });
    promises[1] = Appdata.findOne({ where: {apptableid: _tdTableId, jsondata: { td: dependency}} });

    try {
      const responses = await Promise.all(promises);

      if (responses[0] === null) {
        throw `TD: ${td} not found`;
      } else if (responses[1] === null) {
        _tdNotFound.push(dependency);
        throw `Dependency TD: ${dependency} not found`;
      }

      const tdid = responses[0].dataValues.id;
      const dependencyid = responses[1].dataValues.id;

      Appdata.findOne({
        where: {apptableid: _depTableId, jsondata: { tdid: tdid, dependencyid: dependencyid }}
      })
        .then(response => {
          resolve({ td: response.dataValues, tdid: tdid, dependencyid: dependencyid });
        })
        .catch(error => {
          //console.error(error);
          resolve({ td: undefined, tdid: tdid, dependencyid: dependencyid });
        });
    } catch (err) {
      console.log(err);
      resolve({ td: undefined, tdid: undefined, dependencyid: undefined });
    }
   });
}

function processLine(line) {
  return new Promise((resolve, reject) => {
    const elements = line.split('\t');
    if (elements[1] !== undefined && elements[1] !== '' && elements[6] !== undefined && elements[6] !== '') {
      // const ecp = elements[0];
      const td = elements[1];
      // const tcto = elements[2];
      // const mlTmp = elements[3].replace(/"/g, '').replace(/ /g, '').split(',');
      // const mls = [];
      // _.forEach(mlTmp, it => mls.push(_mlsTypes[it]));
      // const subject = elements[4].replace(/"/g, '');
      const complianceTmp = elements[5];
      const complianceid = _complianceTypes[complianceTmp];
      const dependency = elements[6];
      const purpose = elements[9].replace(/"/g, '');
      const reference = elements[10];
      const notes = elements[11];
      const bunos = [];
      _.forEach(elements.slice(12), (it) => {
        if (it !== undefined && it !== null && it.length > 0) {
          const bunoid = _bunos[it];
          if (bunoid === undefined || bunoid === null) {
            _bunoNotFound.push(it);
          }
          bunos.push(bunoid)
        }
      });
      findDependency(td, dependency)
        .then((resp) => {
          if (resp.td === undefined && resp.tdid !== undefined && resp.dependencyid !== undefined) {
            Appdata
              .build({
                appid: _appId,
                apptableid: _depTableId,
                jsondata: {
                  tdid: resp.tdid,
                  dependencyid: resp.dependencyid,
                  complianceid: complianceid,
                  purpose: purpose,
                  reference: reference,
                  notes: notes,
                  bunos: bunos
                }
              })
              .save()
              .then(results => {
                console.log(`****************** insert: td: ${td}/${resp.tdid}  ` +
                  `dependency: ${dependency}/${resp.dependencyid}  ` +
                  `complianceid: ${complianceid}  ` +
                  `purpose:  ${purpose}  ` +
                  `reference: ${reference}  ` +
                  `notes: ${notes}`);
                console.log(JSON.stringify(bunos));
                resolve();
              })
              .catch(error => {
                console.error(error);
                reject(error);
              });
          } else {
            // possibly update
            resolve();
          }
        });
      // if (it !== '') {
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
          const done = 150;
          // const done = lines.length;
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
        console.log('----- Referenced TDs that were not found -----');
        _.forEach(_tdNotFound, (it) => {
          console.log(it);
        })
        console.log('----- Referenced Bunos that were not found -----');
        _.forEach(_bunoNotFound, (it) => {
          console.log(it);
        })
      });
  })
  .catch(err => {
    console.error('Unable to connect to the database: ', err);
  });


