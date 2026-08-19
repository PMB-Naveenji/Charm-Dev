/*******************************************************************************
 * Copyright (c) 2018 Sparta Systems, Inc.
 ******************************************************************************/

'use strict';

window.AuraErrorType = Object.freeze({
    NotInitialized : 'NOT_INITIALIZED',
    PermissionError : 'PERMISSION_ERROR',
    LockedError: 'LOCKED_ERROR',
    RelatedListsLockedError: 'RELATED_LISTS_LOCKED_ERROR',
    NoResponse: 'NO_RESPONSE',
    Unknown : 'UNKNOWN_ERROR',
    None : 'NO_ERROR'
});

window.AuraResponse = function (response) {
    if(response == undefined){
        response = {
            message : AuraErrorType.NoResponse 
        };
    }
    var parsedResponse = {
        success :   (response.success   ||  false),
        errorType : (response.errorType ||  AuraErrorType.NotInitialized),
        message :   (response.message   ||  'Message Not Set'),
        data :      (response.data      ||  undefined ),

        isSuccessful : function(){
            return this.success
        },
        getErrorMessage : function(){
            return this.message;
        },
        getErrorType : function(){
            return this.errorType
        },
        getData : function(){
            return this.data;
        },
        hasData : function(){
            return (this.data != undefined && this.data != "")
        },
        isErrorType: function(eType){
            return this.errorType == eType;
        }
    };
    return parsedResponse;
};


