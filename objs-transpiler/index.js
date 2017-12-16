require('./uglify.js');

const sweet = require('@sweet-js/core/dist/browser-sweet');
const objs = require('raw-loader!./syntax.js');

const objsHelpers = require('raw-loader!./helpers.js');
const helpers = require('raw-loader!@sweet-js/core/helpers.js');
const allHelpers = objsHelpers + "\n" + helpers;

const options = {
	compress: {
		// disable converting to arrow funcs, as the `arguments` var can't be accessed in them
		reduce_funcs: false,
		// disable removal of unused vars, including where a func argument is modified without being
		// accessed elsewhere. Required because UglifyJS doesn't count the `arguments` var as a "use"
		unused: false
	}
};

module.exports = code => UglifyJS.minify(sweet.compile(objs + "\n" + code, allHelpers).code, options).code;
