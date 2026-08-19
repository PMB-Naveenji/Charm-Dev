/////////////////////////////////////////////////////////////
// String
/////////////////////////////////////////////////////////////
// for IE compatibility - use this instead of String.endsWith
String.prototype.stringEndsWith = function(endsWith) {
	return this.lastIndexOf(endsWith) === (this.length - endsWith.length);
};

String.prototype.contains = function(contains) {
	return this.lastIndexOf(contains) >= 0;
};

/////////////////////////////////////////////////////////////
// StringBuilder
/////////////////////////////////////////////////////////////
function StringBuilder(blockSize) {
	this.__blockSize = blockSize || 100;
	this.__stringLength = 0;
	this.length = blockSize;
}
StringBuilder.prototype = new Array();
StringBuilder.prototype.constructor = StringBuilder;

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

StringBuilder.prototype.toString = function() {
	this.length = this.__stringLength;
	return Array.prototype.join.call(this, "");
};

StringBuilder.prototype.clear = function() {
	this.length = this.__blockSize;
	this.__stringLength = 0;
};


////////////////////////////////////////////////////////
// mdc.Utility
////////////////////////////////////////////////////////

mdc.Utility.prototype.objectValues = function(obj) {
	var values = [];
	for(var key in obj) {
    	values.push(obj[key]);
	}
	return values;
};

mdc.Utility.prototype.__formatIntegerValue = function(stringIntValue) {
	var length = stringIntValue.length;
	if (length <= 3) {
		return stringIntValue;
	}
	
	var stringValueArray = stringIntValue.split("");
	for (var i = length - 3; i > 0; i -= 3) {
		stringValueArray.splice(i, 0, ",");
	}
	return stringValueArray.join("");
};

mdc.Utility.prototype.getNameFieldName = function(sObject) {
	if (sObject === "Case") {
		return "CaseNumber";
	}
	
	return "Name";
};

mdc.Utility.prototype.formatFieldValue = function(fieldValue, fieldType) {
	if (fieldValue === null || typeof(fieldValue) === "undefined") {
		return "";
	}
	
	switch(fieldType) {
		case "percent":	{
			if (!(fieldValue + "").contains(".") || isNaN(fieldValue)) {
				return "";
			}
			return Math.round((Number(fieldValue) * 100)) + "%";
		}
		case "double":
		case "currency": {
			var stringValue = fieldValue.toString();
			var decimalPosition = stringValue.indexOf(".");
			var integerPart = stringValue.substring(0, decimalPosition);
			var decimalPart = decimalPosition >= 0 ? stringValue.substring(decimalPosition + 1) : "";
			return this.__formatIntegerValue(integerPart) + (decimalPart.length > 0 ? ("." + decimalPart) : "");
		}
		case "int": {
			return this.__formatIntegerValue(fieldValue.toString());
		}
		case "date": {
			var date = new Date(fieldValue + (new Date().getTimezoneOffset() * 60000));
			var localeString = date.toLocaleString();
			var commaIndex = localeString.indexOf(",");
			return commaIndex < 0 ? localeString : localeString.substring(0, commaIndex);
		}
		case "datetime": {
			var date = new Date(fieldValue);
			return date.toLocaleDateString() + " - " + date.toLocaleTimeString();
		}
		case "boolean": 
		case "string":
		case "picklist":
		default:
			return fieldValue.toString();
	}
};

mdc.Utility.prototype.unencodeHtml = function(inString) {
	var textArea = document.createElement("textarea");
	textArea.innerHTML = inString;
	return textArea.value;	
};



////////////////////////////////////////////////////////
// mdc.sfdc.PublicGroupUtil
////////////////////////////////////////////////////////


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
// mdc.sfdc.Describe
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
			//descriptor.fields.push({
			//	name: field.name,
			//	label: field.label,
			//	length: field.length
			//});
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