/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : EmailsDeletionBatch.
* @Why   : This class is used to delete EmailMessages for specified user.
* @When  : 02-JAN-2019.
* @Where : From EmailsDeletionPageCtrl page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                 Modification ID          Description
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    02-JAN-2020          Storage Limit            Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    13-JUL-2020          Code Audit               Added class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class EmailsDeletionBatch implements Database.Batchable<sObject>, Database.Stateful {

    global final String Query;

    /*
    * @Constructor  : EmailsDeletionBatch.
    * @Description  : To execute logic upon class initialization.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : String userId.
    */
    global EmailsDeletionBatch (String userId) {
        Query = 'SELECT Id FROM EmailMessage WHERE CreatedById = \'' + userId + '\'';
    }

    /*
    * @Method       : start.
    * @Description  : To collect the records to pass to the execute method.
    * @Invoke       : From EmailsDeletionBatch class.
    * @Return       : Database.QueryLocator.
    * @Params       : Database.BatchableContext BC.
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(Query);
    }

    /*
    * @Method       : execute.
    * @Description  : To do the required processing for each chunk of data.
    * @Invoke       : From EmailsDeletionBatch class.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC, List<sObject> scope.
    */
    global void execute(Database.BatchableContext bc, List<EmailMessage> scope) {
        delete scope;
    }

    /*
    * @Method       : execute
    * @Description  : Empty method.
    * @Invoke       : From EmailsDeletionBatch class.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC.
    */
    global void finish(Database.BatchableContext bc) {

    }
}