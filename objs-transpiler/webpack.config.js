module.exports = {
	entry: './index.js',
	output: {
		library: "OBJSTranspiler",
		libraryTarget: 'umd',
		filename: 'ob.js'
	},
	externals: ["babel-core"]
};
