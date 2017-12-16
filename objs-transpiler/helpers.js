'lang sweet.js';

export function unwrapped(obj) {
	return unwrap(obj).value;
}

// Validate the identifier and unwrap it if it's valid
function nextIdentifier(ctx) {
	const id = ctx.next().value;
	const unwrappedID = unwrapped(id);
	if (!isIdentifier(id)) {
		throw new Error('Invalid identifier: \'' + unwrappedID + '\'');
	}
	return unwrappedID;
}

export function nextClassName(ctx) {
	let classNameParts = [];
	while (true) {
		classNameParts.push(nextIdentifier(ctx));
		const marker = ctx.mark();
		const dot = unwrapped(ctx.next().value);
		if (dot !== '.') {
			ctx.reset(marker);
			break;
		}
	}
	return classNameParts.join(".");
}

export function parseType(typeName) {
	const types = {
		'char': 'c',
		'int': 'i',
		'short': 's',
		'long': 'l',
		'long long': 'q',
		'unsigned char': 'C',
		'unsigned int': 'I',
		'unsigned short': 'S',
		'unsigned long': 'L',
		'unsigned long long': 'Q',
		'float': 'f',
		'double': 'd',
		'BOOL': 'B',
		'void': 'v',
		'char *': '*',
		'id': '@',
		'Class': '#',
		'SEL': ':'
		// TODO: Maybe add support for structs, arrays, ptrs?
	};
	
	const type = types[typeName];
	if (type === undefined) throw new Error('Unknown type \'' + typeName + '\'');
	return type;
}

export function nextType(ctx) {
	const container = ctx.contextify(ctx.next().value);
	let typeName = "";
	let idx = 0;
	while (true) {
		const v = unwrapped(container.next().value);
		if (typeof v !== 'string') {
			if (idx !== 0) break;
			throw new Error('Expected type');
		}
		typeName += (idx === 0 ? '' : ' ') + v;
		idx++;
	}
	return parseType(typeName);
}
