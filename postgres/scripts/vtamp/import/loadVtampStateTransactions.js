#!/usr/bin/env node

const Sequelize = require('../../../node_modules/sequelize');
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

const WorkflowStateTransition = sequelize.define('workflow_statetransitions', {
    appid: { type: Sequelize.INTEGER, allowNull: false },
    actionid: { type: Sequelize.INTEGER, allowNull: true },
    stateinid: { type: Sequelize.INTEGER, allowNull: true },
    stateoutid: { type: Sequelize.INTEGER, allowNull: true },
    label: { type: Sequelize.STRING, allowNull: false },
    allowedroles: { type: Sequelize.ARRAY(Sequelize.INTEGER), allowNull: true },
    createdat: { type: Sequelize.DATE },
    updatedat: { type: Sequelize.DATE }
  },
  {
    schema: 'app',
    timestamps: true,
    createdAt: 'createdat',
    updatedAt: 'updatedat'
  });

const _filePath = process.argv[2];
const _appId = Number(process.argv[3]);
console.log(`path: ${_filePath}  appId: ${_appId}`);

function findStateTransition(label, groupid) {
  return new Promise((resolve) => {
    const allowedroles = [groupid];
    WorkflowStateTransition.findOne({
      where: { label: label, allowedroles: { $contains: allowedroles } }
    })
      .then(response => {
        resolve(response.dataValues);
      })
      .catch(error => {
        // console.error(error);
        resolve(undefined);
      });
  });
}

function processLine(line) {
  return new Promise((resolve) => {
    const elements = line.split(',');
    const label = elements[3];
    const stateinid = elements[4];
    const stateoutid = elements[6];
    const groupid = elements[8];
    const actionid = elements[10];
    if(label !== undefined) {
      console.log(
        `label: ${label}  statein: ${stateinid}  stateout: ${stateoutid}  group: ${groupid}  action: ${actionid}`
      );
      findStateTransition(label, groupid)
        .then((resp) => {
          if (resp === undefined) {
            const allowedroles = [groupid];

            WorkflowStateTransition
              .build({
                appid: _appId,
                label: label,
                stateinid: stateinid,
                stateoutid: stateoutid,
                actionid: actionid,
                allowedroles: allowedroles,
                createdat: sequelize.fn('NOW')
              })
              .save()
              .then(results => {
                console.log(`****************** insert: identifier: ${label}`);
                resolve();
              });
          } else {
            console.log(`-- skip state transition: ${label}`);
            resolve();
          }
        });
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
          // const done = 15;
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
        console.log('Closing');
        sequelize.close();
      })
      .catch((err) => {
        console.error(`****** Error: ${err}`);
        sequelize.close();
    });
  })
  .catch(err => {
    console.error('Unable to connect to the database: ', err);
  });


