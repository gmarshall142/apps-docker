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
console.log(`path: ${_filePath}`);
// const _appId = Number(process.argv[3]);
// const _appTableId = Number(process.argv[4]);
// const _mlsId = Number(process.argv[5]);
// const _complianceId = Number(process.argv[6]);
// const _mlsTypes = {};
// const _complianceTypes = {};
// console.log(`path: ${_filePath}  appId: ${_appId}  apptableId: ${_appTableId}  mlsId: ${_mlsId}  complianceId: ${_complianceId}`);

function findBuno(buno) {
  return new Promise((resolve) => {
    Buno.findOne({
      where: { identifier: buno }
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
      const buno = elements[1].replace(/"/g, '');
      findBuno(buno)
        .then((resp) => {
          if (resp === undefined) {
            // console.log(`****************** insert: identifier: ${buno}`);
            Buno
              .build({
                identifier: buno,
                createdat: sequelize.fn('NOW'),
              })
              .save()
              .then(results => {
                console.log(`****************** insert: identifier: ${buno}`);
                resolve();
              })
              .catch(error => {
                console.error(error);
              });
          } else {
            console.log(`-- skip buno: ${buno}`);
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


