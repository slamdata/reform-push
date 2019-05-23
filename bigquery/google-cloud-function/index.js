const Buffer = require('safe-buffer').Buffer;
const Compute = require('@google-cloud/compute');
const reattempt = require('reattempt-promise-function');

const compute = new Compute();

require('es6-promise').polyfill();

exports.startInstancePubSub = (data, context) => {
  const payload = _validatePayload(JSON.parse(Buffer.from(data.data, 'base64').toString()));
  const vm = compute.zone(payload.zone).vm(payload.instance);
  
  return setMetadata(vm, dekeyvalueize(keyvalueize(payload.metadata).map(predicated(hasKey("startup-script"))(appendValue(finale(resetMetaDataAndShutdown(payload.zone)(keyvalueize(payload.originalMetadata))))))))
      .then(() => vm.stop())
      .then(data => {
        // Operation pending.
        const operation = data[0];
        return operation.promise();
      })
      .then(() => {
        const message = 'Successfully stopped instance ' + payload.instance;
        console.log(message);
        return vm.start();
      })
      .then(data => {
        // Operation pending.
        const operation = data[0];
        return operation.promise();
      })
      .then(() => {
        const message = 'Successfully started instance ' + payload.instance;
        console.log(message);
      });
};

const setMetadata = (vm, metadata) =>
  vm.setMetadata(metadata)
    .then(data => {
      const operation = data[0];
      return operation.promise();
    })
    .then(() =>
       reattempt(() => {
        return vm.getMetadata().then(data => {
          const actual = JSON.stringify(dekeyvalueize(data[0].metadata.items));
          const expected = JSON.stringify(metadata);
          if (actual === expected) {
            return Promise.resolve(data);
          } else {
            return Promise.reject("Retreived metadata didn't equal " + JSON.stringify(metadata));
          }
        });
      }, [], 1000, 20)
    )
    .then(data => {
      console.log("Successfully set metadata " + JSON.stringify(metadata));
    });

const gcloudFormatize = arr => Array.isArray(arr) ? arr.map(obj => obj.key + "=\"" + obj.value + "\"").join(",") : "";

const resetMetaDataAndShutdown = zone => metadata => "gcloud compute instances remove-metadata slamdata-bigquery --all --zone " + zone + (Array.isArray(metadata) && metadata.length > 0 ? " && gcloud compute instances add-metadata slamdata-bigquery --zone " + zone + " --metadata " + gcloudFormatize(metadata) : "") + " && gcloud compute instances stop slamdata-bigquery --zone " + zone;

const finale = s => " && (" + s + ") || (" + s + ")";

const predicated = p => f => x => p(x) ? f(x) : x;

const hasKey = key => obj => obj.key && obj.key === key;

const appendValue = suffix => obj => { return { key: obj.key, value: obj.value + suffix } };

const keyvalueize = obj => Object.keys(obj).map(key => { return { key: key, value: obj[key] }; });

const dekeyvalueize = arr => Array.isArray(arr) ? arr.reduce((acc, obj) => { return { ...acc, [obj.key]: obj.value }; }, {}) : {};

/**
 * Validates that a request payload contains the expected fields.
 *
 * @param {!object} payload the request payload to validate.
 * @returns {!object} the payload object.
 */
function _validatePayload (payload) {
  if (!payload.zone) {
    throw new Error(`Attribute 'zone' missing from payload`);
  } else if (!payload.instance) {
    throw new Error(`Attribute 'instance' missing from payload`);
  } else if (!payload.metadata) {
    throw new Error(`Attribute 'metadata' missing from payload`);
  } else if (!payload.originalMetadata) {
    throw new Error(`Attribute 'originalMetadata' missing from payload`);
  }

  return payload;
}