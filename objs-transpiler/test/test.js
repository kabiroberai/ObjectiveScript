const transpile = require('../ob.js');
const fs = require('fs');
const assert = require('assert');

// Run `script` with `ctx` as the global var
function run(script, ctx) {
	with (ctx) eval(script);
}

// TODO: Add tests for errors

function describeCode(message, code, tests) {
	describe(message, function() {
		before(function() {
			this.code = transpile(code);
		});

		tests.forEach(function(test) {
			it(test.it, function () {
				run(this.code, test);
			});
		});
	});
}

describe('OBJSTranspiler', function() {

	describe('msgSend', function() {
		describeCode('without args', '$[foo bar];', [
			{
				it: 'should have the right target',
				foo: 1,
				msgSend: function (target, sel, ...args) {
					assert.equal(target, 1);
				}
			},
			{
				it: 'should have the right selector',
				foo: 1,
				msgSend: function (target, sel, ...args) {
					assert.equal(sel, 'bar');
				}
			},
			{
				it: 'should have no args',
				foo: 1,
				msgSend: function (target, sel, ...args) {
					assert.equal(args.length, 0);
				}
			}
		]);

		describeCode('with args', '$[foo barWithA:10 b:"hello"];', [
			{
				it: 'should have the right target',
				foo: 1,
				msgSend: function (target, sel, ...args) {
					assert.equal(target, 1);
				}
			},
			{
				it: 'should have the right selector',
				foo: 1,
				msgSend: function (target, sel, ...args) {
					assert.equal(sel, 'barWithA:b:');
				}
			},
			{
				it: 'should have the right args',
				foo: 1,
				msgSend: function (target, sel, ...args) {
					assert.equal(args[0], 10);
					assert.equal(args[1], "hello");
				}
			}
		]);

		describeCode('to a class method', '$[Foo bar];', [
			{
				it: 'should have the right target',
				cls: function (clsName) {
					return "Class named: " + clsName;
				},
				msgSend: function (target, sel, ...args) {
					assert.equal(target, "Class named: Foo");
				}
			}
		]);

		describeCode('with an expression target', '$["hello"+foo bar];', [
			{
				it: 'should have the right target',
				foo: "!",
				msgSend: function (target, sel, ...args) {
					assert.equal(target, 'hello!');
				}
			}
		]);

		describeCode('with an expression argument', '$[foo barWithA:b+c];', [
			{
				it: 'should have one, correct arg',
				foo: 1,
				b: 5,
				c: 6,
				msgSend: function (target, sel, ...args) {
					assert.equal(args.length, 1, "args.length != 1");
					assert.equal(args[0], 11, "args[0] != 11");
				}
			}
		]);

		describeCode('with new as a target', '$[Foo new]', [
			{
				it: 'should have its selector set to `new`',
				cls: function () {
					return ""
				},
				msgSend: function (target, sel, ...args) {
					assert.equal(sel, 'new');
				}
			}
		]);

		// TODO: Add tests for super
	});

	describe('associatedObject', function() {
		describeCode('getter', '$(_foo);', [
			{
				it: 'should have self as its target',
				self: 10,
				associatedObject: function (target, name, val) {
					assert.equal(target, 10);
				}
			},
			{
				it: 'should have the right name',
				self: 10,
				associatedObject: function (target, name, val) {
					assert.equal(name, '_foo');
				}
			}
		]);

		describeCode('setter', '$(_foo) = 30', [
			{
				it: 'should have the right value',
				self: 10,
				associatedObject: function (target, name, val) {
					assert.equal(val, 30);
				}
			}
		]);
	});

	describe('$orig', function() {
		describeCode('with default args', '$orig(_)', [
			{
				it: 'should have the right arguments',
				arguments: ["a", "b", "c", "d", "e"],
				orig: function (args) {
					assert.equal(args.length, 3);
					assert.equal(args[0], "c");
					assert.equal(args[1], "d");
					assert.equal(args[2], "e");
				}
			}
		]);

		describeCode('with custom args', '$orig(a, b)', [
			{
				it: 'should have the right arguments',
				a: "x",
				b: "y",
				orig: function (args) {
					assert.equal(args.length, 2);
					assert.equal(args[0], "x");
					assert.equal(args[1], "y");
				}
			}
		]);
	});
	
	// TODO: Add tests
	
	describe('$class', function() {
		
	});

	describe('$hook', function() {
		// remember to add tests for names with '.' in them, and unicode names too
	});

	describe('Test file', function() {
		it('should compile', function(done) {
			fs.readFile('test/app.objs', function (err, file) {
				if (err) done(err);
				const transpiled = transpile(file);
				// console.log(transpiled);
				done();
			});
		});
	});

});
