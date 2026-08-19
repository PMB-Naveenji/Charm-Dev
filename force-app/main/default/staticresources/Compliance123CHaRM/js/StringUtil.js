/*******************************************************************************
 * Copyright (c) 2018 Sparta Systems, Inc.
 ******************************************************************************/

'use strict';

/**
 * @class StringUtil
 */
var StringUtil = {

    /**
     *
     * @param {String}  inputStr
     * @method escapeSingleQuotes
     * @return String
     */
    escapeSingleQuotes: function(inputStr) {

        //validate input
        if(typeof inputStr === 'undefined' || inputStr === null ) {
            return '';
        }

        return inputStr.replace(/'/g, "\\'");
    }

};




