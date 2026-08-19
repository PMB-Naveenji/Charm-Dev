/////////////////////////////////////////////////////////////
// String
/////////////////////////////////////////////////////////////

// Extends the Javascript String class with a method to test whether the 
// string ends with another string. This was necessary because the 
// Javascript built-in String.endsWith method is not supported in IE 11.

String.prototype.stringEndsWith = function(endsWith) {
	return this.lastIndexOf(endsWith) === (this.length - endsWith.length);
};

// Extends the Javascript String class with a contains method to 
// determine whether a string contains another string
String.prototype.contains = function(contains) {
	return this.lastIndexOf(contains) >= 0;
};

/////////////////////////////////////////////////////////////
// StringBuilder class
//   implements a class similar to the Java StringBuilder in 
//   order to make composing of long strings from shorter 
//   ones more memory-efficient. Call chaining supported.
/////////////////////////////////////////////////////////////

// Constructor - pass a different block size to override the default 100 bytes
function StringBuilder(blockSize) {
	this.__blockSize = blockSize || 100;
	this.__stringLength = 0;
	this.length = blockSize;
}
StringBuilder.prototype = new Array();
StringBuilder.prototype.constructor = StringBuilder;

// Append a string to the end of the StringBuilder
StringBuilder.prototype.append = function(appendString) {
	var _appendString = String(appendString);
	
	if (this.__stringLength + _appendString.length > this.length) {
		this.length += this.__blockSize;
	}
	
	for (var i = 0; i < _appendString.length; i++, this.__stringLength++) {
		this[this.__stringLength] = _appendString[i];
	}
	
	return this;
};

// Convert the StringBuilder to the complete String
StringBuilder.prototype.toString = function() {
	this.length = this.__stringLength;
	return Array.prototype.join.call(this, "");
};

// Clear the StringBuilder and return it to zero length
StringBuilder.prototype.clear = function() {
	this.length = this.__blockSize;
	this.__stringLength = 0;
};


////////////////////////////////////////////////////////
// mdc.Utility
//   This class is declared in mdc_namespace.js. 
//   It implements some general utility methods, 
//   some of the related to Salesforce
////////////////////////////////////////////////////////

// Given a Javascript object, this method returns an Array 
// containing only the map values without the keys.
mdc.Utility.prototype.objectValues = function(obj) {
	var values = [];
	for(var key in obj) {
    	values.push(obj[key]);
	}
	return values;
};

// Don't use String.startsWidth - no IE support
// Method that works with all browsers
mdc.Utility.prototype.stringStartsWith = function(inString, startString) {
	return inString.indexOf(startString) === 0;
};

// Don't use String.startsWidth - no IE support
// Method that works with all browsers
mdc.Utility.prototype.stringEndsWith = function(inString, endString) {
	// hello lo
	return inString.lastIndexOf(endString) === (inString.length - endString.length);
};

// Almost all Salesforce objects have a Name field with the API 
// name “Name”. Some have alternate name field names. This method 
// will return the name field name given the object name
mdc.Utility.prototype.getNameFieldName = function(sObject) {
	if (sObject === "Case") {
		return "CaseNumber";
	}
	
	return "Name";
};

// Given a field value and a field type, this method will attempt to attach some formatting to it:
//  o	percent fields – “%” string is appended to the end
//  o	number, int, double, currency fields – applies locale-specific number formatting (e.g. for US locale, inserts commas
//  o	date fields – formats the date to the user’s locale
//  o	datetime fields – formats the datetime to the user’s locale
//  o	boolean – returns a String “true” or “false”
//  o   string or picklist fields – returns the original string

mdc.Utility.prototype.formatFieldValue = function(fieldValue, fieldType) {


	if (fieldValue === null || typeof(fieldValue) === "undefined") {
		return "";
	}

	
	//// If a String is passed in that looks like a number, treat it as a number
	//if (fieldValue && !isNaN(fieldValue) && !this.stringStartsWith(fieldValue, "0") {
	//	fieldValue = Number(fieldValue);
	//	fieldType = "number";
	//}
	
	var _fieldType = typeof(fieldType) === "undefined" ? (isNaN(fieldValue) ? "string" : "number") : fieldType;
	
	
	switch(_fieldType) {
		case "percent":	{
			if (isNaN(fieldValue)) {
				return "";
			}
			return fieldValue.toLocaleString() + "%";
		}
		case "number":
		case "int":
		case "double":
		case "currency": {
			if (isNaN(fieldValue)) {
				return "";
			}
			return fieldValue.toLocaleString();
		}
		case "date": {
			var date = new Date(fieldValue);
	
			// IE separates date and time with a space, Firefox and Chrome use a comma
			var localeString = date.toLocaleString();
			var separatorIndex = localeString.indexOf(",");
			separatorIndex = separatorIndex === -1 ? localeString.indexOf(" ") : separatorIndex;
			return separatorIndex < 0 ? localeString : localeString.substring(0, separatorIndex);
		}
		case "datetime": {
			var date = new Date(fieldValue);
			return date.toLocaleDateString() + " - " + date.toLocaleTimeString();
		}
		case "boolean": {
			if (fieldValue === null || typeof(fieldValue) === "undefined") {
				return "";
			}
			return fieldValue.toString();
		}
		case "string":
		case "picklist":
		default: {
			if (!fieldValue) {
				return "";
			}
			return fieldValue.toString();
		}
	}
};

// Converts entity encoded HTML to HTML (e.g. this method 
// will convert (“&lt;div&rt;” with “<div>”)
mdc.Utility.prototype.unencodeHtml = function(inString) {
	var textArea = document.createElement("textarea");
	textArea.innerHTML = inString;
	return textArea.value;	
};

// Escapes any single or double quotes found in a string 
// (e.g. this method converts the string [abc’d’ef”gh] into [abc\’d\’ef\’’gh]
mdc.Utility.prototype.escapeQuotes = function(inString) {
	var result = inString.replace(/\'/gi, "\\'");
	return result.replace(/\"/gi, '\\"');
};

// This method replaces Carriage Return and Line Feed codes in a string 
// with HTML breaks <br />. For example the string “abc\r\ndef\n” 
// will be replaced by “abc<br />def<br/>. It replaces “\r\n” and “\r” and “\n”
mdc.Utility.prototype.replaceCrLf = function(inString) {
	
	return inString.replace(/(?:\\[rn]|[\r\n]+)+/g, "<br />");
};

////////////////////////////////////////////////////////
// mdc.sfdc.PublicGroupUtil
// This class contains helper methods for Public Group membership
////////////////////////////////////////////////////////

// Given a User ID and name of a Public Group determine if they user
// is directly or indirectly a member of the group
mdc.sfdc.PublicGroupUtil.prototype.isUserInGroup = function(userId, groupName) {

       var connection = new mdc.sfdc.Connection();
	
	// user directly in group
	var sb = new StringBuilder();
	sb.append("SELECT COUNT() FROM GroupMember WHERE Group.Name = '");
	sb.append(groupName);
	sb.append(" AND UserOrGroupId = '");
	sb.append(userId);
	sb.append("'");
	
	if (connection.query().size > 0){
		return true;
	};
};

// private method
mdc.sfdc.PublicGroupUtil.prototype.__userInPublicGroup = function(userId, userRoleId, publicGroupId, connection) {

	var directUser = connection.query("SELECT Id FROM GroupMember" +
		" WHERE Group.Id = '" + publicGroupId + "' AND UserOrGroupId = '" + userId + "'");
	
	if (directUser.length > 0)
	{
		return true;		
	}
	
	//var userRoleInGroup = connection.query("SELECT Id FROM GroupMember WHERE Group.Id ='" + publicGroupId + "'" +
	//	" AND UserOrGroupId IN(SELECT Id FROM Group WHERE RelatedId ='" + userRoleId + "')");

	var userRoleInGroup = [];
	
	if (userRoleId !== null) {
		userRoleInGroup = connection.query("SELECT Id FROM GroupMember WHERE Group.Id ='" + publicGroupId + "'" +
			" AND UserOrGroupId IN(SELECT Id FROM Group WHERE RelatedId ='" + userRoleId + "')");
	}
	
	if (userRoleInGroup.length > 0)
	{
		return true;		
	}		
	
	// find all public groups contained in this public group and recursive call __userInPublicGroup
	var publicGroupGroups = connection.query("SELECT Id, Name FROM Group WHERE Type='Regular' AND Id IN (" +
		"SELECT UserOrGroupId FROM GroupMember WHERE Group.Id = '" + publicGroupId + "')");
		
	for (var i = 0; i < publicGroupGroups.length; i++) {
		var publicGroupGroup = publicGroupGroups[i];
		if (this.__userInPublicGroup(userId, userRoleId, publicGroupGroup.Id, connection)) {
			return true;
		}
	}		
	
	return false;
};

// Given a User ID, return an array of all Public Groups to which the user belongs
mdc.sfdc.PublicGroupUtil.prototype.getAllPublicGroupsForUser = function(userId) {

	var userPublicGroups = {};
       var connection = new mdc.sfdc.Connection();

	var allPublicGroups = 
		connection.query("SELECT Id, Name FROM Group WHERE Type = 'Regular'");
		
	var roleUsers = connection.query("SELECT UserRoleId FROM User WHERE Id = '" + userId + "'");
	var userRoleId = (roleUsers.length > 0 && roleUsers[0].UserRoleId !== null) ? roleUsers[0].UserRoleId : null;
		
	for (var i = 0; i < allPublicGroups.length; i++) {
		var publicGroup = allPublicGroups[i];
		
		if (this.__userInPublicGroup(userId, userRoleId, publicGroup.Id, connection)) {
			userPublicGroups[publicGroup.Id] = publicGroup.Name;
		}
	}
			
	return Util.objectValues(userPublicGroups);
	
};

////////////////////////////////////////////////////////
// mdc.sfdc.Describe - fetch Salesforce metadata
////////////////////////////////////////////////////////
mdc.sfdc.Describe.prototype.describeSObject = function(objectName) {

	if (!this.ObjectDescriptors[objectName]) {
	
		var describe = sforce.connection.describeSObject(objectName);
		
		var descriptor = {
			label: describe.label,
			fieldsByName: {},
			getFieldLabel: function(fieldName) {
			
				var fieldData = this.fieldsByName[fieldName];
				if (fieldData) {
					return fieldData.label;
				}
				
				return "";
			},
			getFieldLabelWithoutID: function(fieldName) {
				var fieldLabel = this.getFieldLabel(fieldName);
				if (fieldLabel.stringEndsWith(" ID")) {
					fieldLabel = fieldLabel.substr(0, fieldLabel.length - " ID".length);
				}
				
				return fieldLabel;				
			},
			getFieldType: function(fieldName) {
				var fieldData = this.fieldsByName[fieldName];
				if (fieldData) {
					return fieldData.type;
				}
				
				return "";
			}				
		};
		
		for (var i = 0; i < describe.fields.length; i++) {

			var fieldData = describe.fields[i];
			descriptor.fieldsByName[fieldData.name] = fieldData;
		}
		
		this.ObjectDescriptors[objectName] = descriptor;
	}
	
	return this.ObjectDescriptors[objectName];
};	

mdc.sfdc.Describe.prototype.ObjectDescriptors = {};

// fix IE 10 support for window.location.origin
if (!window.location.origin) {
 	window.location.origin = window.location.protocol + "//" + window.location.hostname + (window.location.port ? ":" + window.location.port : "");
}	

var urlParams;
(window.onpopstate = function() {
    var match,
        pl = /\+/g,  // Regex for replacing addition symbol with a space
        search = /([^&=]+)=?([^&]*)/g,
        decode = function(s) { 
        	return decodeURIComponent(s.replace(pl, " ")); 
        },
        query = window.location.search.substring(1);

    urlParams = {};
    while (match = search.exec(query))
       urlParams[decode(match[1])] = decode(match[2]);
})();
	
