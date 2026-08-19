/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : SendAttachmentToTIBCOBatch.
* @Why   : To send batch of attachments to TIBCO.
* @When  : 22-FEB-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    22-FEB-2019            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class SendAttachmentToTIBCOBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{

    global final Set<Id> attachmentRecordIdSet;

    /*
    * @Method       : SendAttachmentToTIBCOBatch.
    * @Description  : Constructor.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : Set<Id> attachIdSet.
    */
    global SendAttachmentToTIBCOBatch(Set<Id> attachIdSet) {
        attachmentRecordIdSet = attachIdSet;
    }

    /*
    * @Method       : start.
    * @Description  : To query Attachment__c records.
    * @Invoke       : N/A.
    * @Return       : Database.QueryLocator.
    * @Params       : Database.BatchableContext BC.
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id, File_Name__c, CMSNext_Ticket_Number__c FROM Attachment__c WHERE Id IN : attachmentRecordIdSet');
    }

    /*
    * @Method       : execute.
    * @Description  : To insert error logs.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC, List<Attachment__c> scope.
    */
    global void execute(Database.BatchableContext BC, List<Attachment__c> scope){
        List<Error_Log__c> errorLogs = new List<Error_Log__c> ();
        for(Attachment__c objAttach : scope){
            Error_Log__c errorLog = SendAttachmentToTIBCOService.sendAttachment(objAttach);
            if (errorLog != null) {
                errorLogs.add(errorLog);
            }
        }
        if (errorLogs.size() >= 0) {
            insert errorLogs;
            errorLogs.clear();
        }
    }

    /*
    * @Method       : finish.
    * @Description  : N/A.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC.
    */
    global void finish(Database.BatchableContext BC) {}
}