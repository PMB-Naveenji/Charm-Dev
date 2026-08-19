/*******************************************************************************
 * Copyright (c) 2018 Sparta Systems, Inc.
 ******************************************************************************/

/**
 * @class
 * Common LEX and navigation operation
 * @since                   :       Platform 3.9, Complaints 6.4
 * @version                 :       Platform 3.8, Complaints 6.3
 */
var lexUtil = (function () {
    "use strict";

    /**
     * @constant
     * @type                :       {Boolean}
     * @since               :       Platform 3.9, Complaints 6.4
     * @version             :       Platform 3.9, Complaints 6.4
     */
    var isInLightningExperience =
        typeof sforce !== "undefined" && sforce && sforce.one;

    /**
     * @constant
     * @type                :       {Boolean}
     * @since               :       Platform 3.9, Complaints 6.4
     * @version             :       Platform 3.9, Complaints 6.4
     */
    var isInConsole =
        typeof sforce !== "undefined" && sforce
        && typeof sforce.console !== "undefined" && sforce.console
        && sforce.console.isInConsole();

    /**
     * @function
     * Navigate to record creation page.
     * @param               :       {String} prefix -- object record prefix
     * @param               :       {String} objectAPIName -- API name of the object
     * @param               :       {String} recordType -- record type for object
     * @param               :       {Object} defaultFields -- default fields to set on new record
     * @since               :       Platform 3.9, Complaints 6.4
     * @version             :       Platform 3.9, Complaints 6.4
     */
    var createRecordPage = function(prefix, objectAPIName, recordType, defaultFields) {
        if (isInLightningExperience && objectAPIName) {
            sforce.one.createRecord(objectAPIName, recordType, defaultFields);
        } else if (!isInLightningExperience && prefix && prefix !== null && prefix !== '') {
            window.top.location.href = "/" + prefix + "/e?retURL=%2F" + prefix + "%2Fo";
        }
    };

    /**
     * @function
     * Navigate to record edit page.
     * @param               :       {String} recordId -- id of the record to edit
     * @since               :       Platform 3.9, Complaints 6.4
     * @version             :       Platform 3.9, Complaints 6.4
     */
    var editRecordPage = function(recordId) {
        if (recordId) {
            if (isInLightningExperience) {
                sforce.one.editRecord(recordId);
            } else {
                window.top.location.href = "/" + recordId + "/e?retURL=%2F" + recordId;
            }
        }
    };

    /**
     * @function
     * Navigate to record view page.
     * @param               :       {String} recordId -- id of the record to view
     * @since               :       Platform 3.9, Complaints 6.4
     * @version             :       Platform 3.9, Complaints 6.4
     */
    var viewRecordPage = function(recordId) {
        if (recordId) {
            if (isInLightningExperience) {
                sforce.one.navigateToSObject(recordId, "detail");
            } else {
                window.top.location.href = "/" + recordId;
            }
        } else {
            window.top.location.reload();
        }
    };

    /**
     * @function
     * Navigates to the previous state that’s saved in sforce.one history.
     * @since               :       Platform 3.9, Complaints 6.4
     * @version             :       Platform 3.9, Complaints 6.4
     */
    var goBack = function() {
        if (isInLightningExperience) {
            sforce.one.back(true);
        } else {
            window.history.back();
        }
    };

    /**
     * @function
     * Navigate to url, handles Classic and Lightning navigation.
     * @param               :       {String} url -- destination url
     * @param               :       {Boolean} bypassLightningNavigation -- whether or not to use lightning navigation
     * @since               :       Platform 3.9, Complaints 6.4
     * @version             :       Platform 3.9, Complaints 6.4
     */
    var goToUrl = function(url, bypassLightningNavigation) {
        if (url) {
            if (isInLightningExperience && !bypassLightningNavigation) {
                sforce.one.navigateToURL(url, true);
            } else {
                window.top.location.href = url;
            }
        }
    };

    return {
        /***********************************************************************
         *          FOR BACKWARD COMPATIBILITY : PLATFORM 3.8
         **********************************************************************/

        /**
         * @function
         * Determines if the user is in console
         * @return           :       {boolean} isInConsole -- true if is in Console, false otherwise
         * @since            :       Platform 3.8, Complaints 6.3
         * @version          :       Platform 3.8, Complaints 6.3
         */
        inConsole: function() {
            return isInConsole;
        },

        /**
         * @function
         * Determines if the browser is set to the Lightning or Classic experience.
         * @return          :       {boolean} isInLightningExperience -- true if is in LEX, false otherwise
         * @since           :       Platform 3.8, Complaints 6.3
         * @version         :       Platform 3.8, Complaints 6.3
         */
        inLEX: function () {
            return isInLightningExperience;
        },

        /**
         * @function
         * Performs the LEX navigation to the sObject Detail Page.
         * @param           :       {String} sObjectId -- the sObject Id to open for modification
         * @since           :       Platform 3.8, Complaints 6.3
         * @version         :       Platform 3.8, Complaints 6.3
         */
        lexNavigateToSObject: function (sObjectId) {
            sforce.one.navigateToSObject(sObjectId, "detail");
        },

        /**
         * @function
         * Performs the LEX navigation to the input urlString.
         * @param           :       {String} urlStr -- the URL to navigate to
         * @since           :       Platform 3.8, Complaints 6.3
         * @version         :       Platform 3.8, Complaints 6.3
         */
        lexNavigateToURL: function (urlStr) {
            sforce.one.navigateToURL(urlStr);
        },

        /**
         * @function
         * Navigates to the previous state that’s saved in sforce.one history and refresh the page.
         * @since           :       Complaints 6.3
         * @version         :       Complaints 6.3
         */
        lexRefresh :  function () {
            sforce.one.back(true);
        },

        /**
         * @function
         * Creates record for given object.
         * @param           :       {String} objectAPIName -- API name of the object
         * @param           :       {String} recordType -- record type for object
         * @param           :       {Object} defaultFields -- default fields to set on new record
         * @since           :       Complaints 6.3
         * @version         :       Complaints 6.3
         */
        createRecord: function(objectAPIName, recordType, defaultFields) {
            sforce.one.createRecord(objectAPIName, recordType, defaultFields);
        },

        /**
         * @function
         * Detects if browser Edge or IE.
         * @return          :       {boolean} -- true is browser is IE/Edge, false otherwise
         * @since           :       Complaints 6.3
         * @version         :       Complaints 6.3
         */
        isIEOrEdge: function() {
            var isIE = !!document.documentMode; // Internet Explorer 6-11
            var isEdge = !document.documentMode && !!window.StyleMedia; // Edge 20+
            
            return (isIE || isEdge); 
        },

        /**
         * @function
         * For Console app, refresh and get the Primary Tab.
         * @since           :       Complaints 6.3
         * @version         :       Complaints 6.3
         */
        refreshParentTab: function () {
            sforce.console.getEnclosingPrimaryTabId(refreshTab);
        },

        /**
         * @function
         * Refresh the Primary Tab of Console app.
         * @param           :       result -- current tab information
         * @since           :       Complaints 6.3
         * @version         :       Complaints 6.3
         */
        refreshTab: function (result) {
            sforce.console.refreshPrimaryTabById(result.id);
        },

        /**
         * @function
         * Navigates based on user experience.
         * @param           :       {String} recordId -- id of the record
         * @param           :       {String} pageId -- id of the page
         * @since           :       Complaints 6.3
         * @version         :       Complaints 6.3
         */
        navigateByUserTheme: function(recordId, pageId) {
            if (lexUtil.inLEX()) {
                lexUtil.lexNavigateToSObject(recordId);
            } else if (lexUtil.inConsole()) {  
                lexUtil.refreshParentTab();
            } else if (lexUtil.isIEOrEdge()) {
                window.top.location = '/' + recordId; 
            } else {
                window.top.location = '/'+ recordId + '#' + pageId;                           
            }
        },

        /***********************************************************************
         *          FOR PLATFORM 3.9+
         **********************************************************************/

        back: goBack,
        refresh: viewRecordPage,
        navigateTo: goToUrl,
        viewRecord: viewRecordPage,
        editRecord: editRecordPage,
        createNewRecord: createRecordPage
    };
}());




