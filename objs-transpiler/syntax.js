import { 
	unwrap, isIdentifier, isBrackets, isBraces, isParens, isPunctuator, isKeyword, fromStringLiteral, fromIdentifier, 
	unwrapped, nextClassName, parseType, nextType
} from 'sweet.js/helpers' for syntax;

syntax $ = ctx => {
	const container = ctx.next().value;

	if (isParens(container)) { // associatedObject
		const contCtx = ctx.contextify(container);
		const objNameValue = contCtx.next().value;
		if (!isIdentifier(objNameValue)) throw new Error("Expected identifier as associatedObject name");
		const objName = unwrapped(objNameValue);
		// use objNameValue as lex context
		const objNameLiteral = fromStringLiteral(objNameValue, objName);
		const marker = ctx.mark();
		const equals = unwrapped(ctx.next().value);
		let val = #``;
		if (equals === '=') {
			val = ctx.expand('expr').value;
		} else {
			ctx.reset(marker);
		}
		const selfIdentifier = fromIdentifier(objNameValue, "self");
		// without third argument, returns obj value. with third argument, sets obj value
		return #`associatedObject(${selfIdentifier}, ${objNameLiteral}, ${val})`
	}

	if (!isBrackets(container)) throw new Error('Expected square brackets');
	
	const value = ctx.contextify(container);
	
	const marker = value.mark();
	const id = value.next().value;
	value.reset(marker);
	let target = value.expand('expr').value;
	let msgFunc = #`msgSend`;

	const dummy = id; // use id as the lexical context

	if (target.type === "Super") {
		target = fromIdentifier(dummy, "self");
		msgFunc = #`msgSendSuper`;
	} else if (target.type === "IdentifierExpression") {
		const targetLiteral = fromStringLiteral(dummy, unwrapped(id));
		target = #`(typeof ${target} === "undefined") ? cls(${targetLiteral}) : ${target}`;
	}
	
	let sel = '';
	let args = #``;
	let _first = true;
	while (true) {
		const first = _first;
		_first = false;
		
		const selPartVal = value.next().value;
		const isNewKeyword = isKeyword(selPartVal) && unwrapped(selPartVal) === 'new';
		if (selPartVal === null) {
			if (first) throw new Error('Expected selector');
			break;
		} else if (!isIdentifier(selPartVal) && !isNewKeyword) {
			throw new Error('Expected selector to be identifier but got ' + JSON.stringify(selPartVal));
		}
		
		const selPart = unwrapped(selPartVal);
		if (selPart === ':') {
			selPart = '';
		} else {
			const colon = value.next().value;
			if (unwrapped(colon) !== ':') {
				if (first && colon === null) {
					sel += selPart;
					break;
				}
				throw new Error('Expected `:`');
			}
		}
		sel += selPart + ':';
		
		const next = value.expand('expr').value;
		if (next === null) throw new Error('Expected argument');
		args = args.concat(#`${next},`);
	}
	
	const selLiteral = fromStringLiteral(dummy, sel);
	return #`${msgFunc}(${target}, ${selLiteral}, ${args})`;
};

syntax $orig = ctx => {
	let finalArgs;

	const args = ctx.next().value;
	if (!isParens(args)) throw new Error("Expected parentheses after $orig");

	const firstArg = ctx.contextify(args).next().value;
	// Use all args passed in to method if _ is specified.
	// isIdentifier ensures that it's _ by itself, not in a string like "_"
	if (isIdentifier(firstArg) && unwrapped(firstArg) === '_') {
		// Converts arguments into a proper array with spread operator
		// Also slices from 2nd idx to ignore _orig and self args
		finalArgs = #`[...arguments].slice(2)`;
	} else {
		// Otherwise use the args passed to $orig
		let argList = #``;
		const argsCtx = ctx.contextify(args);
		while (true) {
			const marker = argsCtx.mark();
			const token = argsCtx.next().value;
			if (isPunctuator(token) && unwrapped(token) === ',') continue;
			argsCtx.reset(marker);
			const val = argsCtx.expand('expr').value;
			if (val === null) break;
			argList = argList.concat(#`${val},`);
		}
		finalArgs = #`[${argList}]`;
	}

	// use firstArg as the lexical context for orig
	const origIdentifier = fromIdentifier(firstArg, "orig");

	return #`${origIdentifier}(${finalArgs})`;
}

syntax $class = ctx => {
	const dummy = #`x`.get(0);
	const makeStringLiteral = v => fromStringLiteral(dummy, v);
	
	const name = nextClassName(ctx);
	const nameLiteral = makeStringLiteral(name);
	
	const colon = unwrapped(ctx.next().value);
	if (colon !== ":") {
		throw new Error('Class \'' + name + '\' defined without specifying a base class');
	}
	
	const superclass = nextClassName(ctx);
	const superclassLiteral = makeStringLiteral(superclass);
	
	let protocols = #``;
	const protoMarker = ctx.mark();
	const bracket = unwrapped(ctx.next().value);
	if (bracket === "<") {
		while (true) {
			const protoName = nextClassName(ctx);
			const delim = unwrapped(ctx.next().value);
			const protoLiteral = makeStringLiteral(protoName);
			protocols = protocols.concat(#`${protoLiteral},`);
			if (delim === ">") break;
		}
	} else {
		ctx.reset(protoMarker);
	}
	
	let associatedObjects = #``;
	const objMarker = ctx.mark();
	const objList = ctx.next().value;
	if (isBraces(objList)) {
		const objCtx = ctx.contextify(objList);
		let typeList = [];
		while (true) {
			const typeVal = objCtx.next().value;
			const type = unwrapped(typeVal);
			if (type === undefined) {
				break;
			} else if (isPunctuator(typeVal) && type === ';' && typeList.length > 1) {
				const objName = typeList.pop();
				const typeName = typeList.join(' ');
				const parsedType = parseType(typeName);
				
				typeList = [];
				
				const objLiteral = makeStringLiteral(objName);
				const typeLiteral = makeStringLiteral(parsedType);
				
				associatedObjects = associatedObjects.concat(#`${objLiteral}: ${typeLiteral},`);
			} else if (isIdentifier(typeVal)) {
				typeList.push(type);
			} else {
				throw new Error("Expected type or identifier");
			}
		}
	} else {
		ctx.reset(objMarker);
	}
	
	let methods = #``;
	// loop through all methods
	while (true) {
		let sig = '';
		let sel = '';
		
		const indicator = unwrapped(ctx.next().value);
		if (indicator === '$end') break;
		else if (indicator === '+' || indicator === '-') sel += indicator;
		else throw new Error('Expected method but found \'' + indicator + '\'');
		
		// return type
		sig += nextType(ctx);
		sig += parseType('id') + parseType('SEL'); // implicit (id)self & (SEL)_cmd args

		let argNames = #``;
		let body;
		
		let idx = 0;
		// loop through sel parts
		while (true) {
			const selPartOrBody = ctx.next().value;
			const selPart = unwrapped(selPartOrBody);
			if (typeof selPart !== 'string') {
				if (idx !== 0) {
					body = selPartOrBody;
					break;
				}
				throw new Error('Expected method name');
			}
			sel += selPart;
			const wrappedSep = ctx.next().value;
			const sep = unwrapped(wrappedSep);
			if (sep !== ":") {
				if (idx === 0) {
					body = wrappedSep;
					break;
				}
				throw new Error('Expected \':\'');
			}
			sel += ":";
			sig += nextType(ctx);
			
			const argName = ctx.next().value;
			if (!isIdentifier(argName)) throw new Error('Expected identifier');
			argNames = argNames.concat(argName);
			idx++;
		}
		
		// So that self has the same "_foo" appended to it
		const selfIdentifier = fromIdentifier(unwrapped(body).get(0), "self");

		const sigLiteral = makeStringLiteral(sig + sel);
		if (!isBraces(body)) throw new Error('Expected method body');
		methods = methods.concat(#`${sigLiteral}: function (${selfIdentifier}, ${argNames}) ${body},`);
	}
	
	return #`defineClass(${nameLiteral}, ${superclassLiteral}, [${protocols}], {${associatedObjects}}, {${methods}})`;
};

syntax $hook = ctx => {
	const dummy = #`x`.get(0);
	const makeStringLiteral = v => fromStringLiteral(dummy, v);
	
	const name = nextClassName(ctx);
	const nameLiteral = makeStringLiteral(name);
	
	let associatedObjects = #``;
	const objMarker = ctx.mark();
	const objList = ctx.next().value;
	if (isBraces(objList)) {
		const objCtx = ctx.contextify(objList);
		let typeList = [];
		while (true) {
			const typeVal = objCtx.next().value;
			const type = unwrapped(typeVal);
			if (type === undefined) {
				break;
			} else if (isPunctuator(typeVal) && type === ';' && typeList.length > 1) {
				const objName = typeList.pop();
				const typeName = typeList.join(' ');
				const parsedType = parseType(typeName);
				
				typeList = [];
				
				const objLiteral = makeStringLiteral(objName);
				const typeLiteral = makeStringLiteral(parsedType);
				
				associatedObjects = associatedObjects.concat(#`${objLiteral}: ${typeLiteral},`);
			} else if (isIdentifier(typeVal)) {
				typeList.push(type);
			} else {
				throw new Error("Expected type or identifier");
			}
		}
	} else {
		ctx.reset(objMarker);
	}

	let methods = #``;
	// loop through all methods
	while (true) {
		let sel = '';
		
		const indicator = unwrapped(ctx.next().value);
		if (indicator === '$end') break;
		else if (indicator === '+' || indicator === '-') sel += indicator;
		else throw new Error('Expected method but found \'' + indicator + '\'');

		// nextType(ctx); // eat return type (inferred at runtime)

		let argNames = #``;
		let body;
		
		let idx = 0;
		// loop through sel parts
		while (true) {
			const selPartOrBody = ctx.next().value;
			const selPart = unwrapped(selPartOrBody);
			if (typeof selPart !== 'string') {
				if (idx !== 0) {
					body = selPartOrBody;
					break;
				}
				throw new Error('Expected method name');
			}
			sel += selPart;
			const wrappedSep = ctx.next().value;
			const sep = unwrapped(wrappedSep);
			if (sep !== ":") {
				if (idx === 0) {
					body = wrappedSep;
					break;
				}
				throw new Error('Expected \':\'');
			}
			sel += ":";
			// nextType(ctx); // eat arg type (inferred at runtime)
			
			const argName = ctx.next().value;
			if (!isIdentifier(argName)) throw new Error('Expected identifier');
			argNames = argNames.concat(argName);
			idx++;
		}
		
		const lexicalContext = unwrapped(body).get(0);
		// So that self and _orig have the same "_foo" appended to it
		const selfIdentifier = fromIdentifier(lexicalContext, "self");
		const origIdentifier = fromIdentifier(lexicalContext, "orig");

		const selLiteral = makeStringLiteral(sel);
		if (!isBraces(body)) throw new Error('Expected method body');
		methods = methods.concat(
			#`${selLiteral}: function (${origIdentifier}, ${selfIdentifier}, ${argNames}) ${body},`
		);
	}
	
	return #`hookClass(${nameLiteral}, {${associatedObjects}}, {${methods}})`;
};
