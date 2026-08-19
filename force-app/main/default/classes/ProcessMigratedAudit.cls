/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : ProcessMigratedAudit.
* @Why   : Process Migrated Audit Records.
* @When  : 22-JAN-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 22-JAN-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 15-JUN-2020         Code Audit                        Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 16-JUN-2020         Defect #101.1                     Removed hardcoded emails.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 18-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class ProcessMigratedAudit implements Database.Batchable<sObject>, Database.Stateful {
    String objectApiName, userName, statusApiName, ruleApiName;
    Set<Id> recordIds = new Set<Id>();  // MR - 23MAY19 - Added for processing selected records
    Id userId;
    boolean auditOnlyFlag = false;
    Integer days = Integer.valueOf(Label.Migration_Date_Range_In_Days);
    Date dateRange = System.today().addDays(-days);
    Map<Id, String> wfhParentRecordIdMap = new Map<Id, String>();
    Map<Id, String> ahParentRecordIdMap = new Map<Id, String>();

    /*
    * @Method       : ProcessMigratedAudit Constructor.
    * @Description  : To handle  the logic in Process Migrated Audit.
    * @Invoke       : N/A.
    * @Return       : N/A
    * @Params       : String objectApiName
    */
    public ProcessMigratedAudit(String objectApiName){
        this.objectApiName = objectApiName;
        userName = Label.Migration_User_Name;
        userId = [SELECT id, Name, Email FROM User WHERE Username = :userName].Id;
    }

    /*
    * @Method       : ProcessMigratedAudit Constructor.
    * @Description  : For processing selected records.
    * @Invoke       : N/A.
    * @Return       : N/A
    * @Params       : String objectApiName, Set<Id> inpRecordIds
    */
    // MR - 23MAY19 - Added for processing selected records
    public ProcessMigratedAudit(String objectApiName, Set<Id> inpRecordIds) {
        this.objectApiName = objectApiName;
        recordIds = inpRecordIds;
    }

    /*
    * @Method       : start.
    * @Description  : To handle start batch job.
    * @Invoke       : N/A.
    * @Return       : Database.getQueryLocator(query).
    * @Params       : Database.BatchableContext BC.
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = '';
        String whereClause = ' WHERE CreatedById = :userId AND CreatedDate > :dateRange';

        if(this.recordIds.size() > 0) { whereClause = ' WHERE Id IN :recordIds'; }       // MR - 23MAY19 - Added for processing selected records

        if(objectApiName.equals('CMPL123CME__Complaint__c')) {
            query = 'SELECT Id, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__CMPL123_WF_Action__c, CreatedById, CMPL123Rule_Key_Value__c, Ticket_Type__c FROM ' + objectApiName + whereClause;
        } else if(objectApiName.equals('CMPL123CME__EMDR__c')) {
            query = 'SELECT Id, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__CMPL123_WF_Action__c, CreatedById, CMPL123CME__CMPL123Rule_Key_Value__c FROM ' + objectApiName + whereClause;
        } else if(objectApiName.equals('Product_Lot__c') || objectApiName.equals('Contact__c') || objectApiName.equals('Product_Ticket__c')) {
            auditOnlyFlag = true;
            query = 'SELECT Id, CreatedById FROM ' + objectApiName + whereClause;
        } else {
            query = 'SELECT Id, CMPL123_WF_Status__c, CMPL123_WF_Action__c, CreatedById, CMPL123Rule_Key_Value__c FROM ' + objectApiName + whereClause;
        }

        return Database.getQueryLocator(query);
    }

    /*
    * @Method       : execute.
    * @Description  : To handle execute batch job.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC, List<SObject> lstRecords.
    */
    global void execute(Database.BatchableContext BC, List<SObject> lstRecords) {
        Map<Id, SObject> wfhObjectRecordsMap = new Map<Id, SObject>();
        Map<Id, SObject> ahObjectRecordsMap = new Map<Id, SObject>();
        Map<String,CMPL123__WF_Step__c> mapWFStepWithRuleKey = New Map<String,CMPL123__WF_Step__c>();
        Set<String> setWfStatus = new Set<String>();
        Set<String> setWFRuleKeyValue = new  Set<String>();

        for(SObject obj : lstRecords) {
            ahObjectRecordsMap.put(obj.id, obj);
        }

        if(ahObjectRecordsMap.size() > 0) {
            createAuditHistoryRecords(ahObjectRecordsMap.values());
        }
    }

    /*
    * @Method       : finish.
    * @Description  : To handle finish batch job.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC.
    */
    global void finish(Database.BatchableContext BC){
        // 19MAR19 - Send an Email with the list of processed Records
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('Batch Processing for ' + objectApiName + ' on ' + System.today());
        String body = 'Summary of the processing happened for ' + objectApiName + '<br/>';

        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment wfhAttachment = new Messaging.EmailFileAttachment();
        Messaging.EmailFileAttachment ahAttachment = new Messaging.EmailFileAttachment();


        if(ahParentRecordIdMap.size() > 0) {
            body += '<br/> ' + ahParentRecordIdMap.size() + ' number of records for which Audit History processing completed.';
            body += '<br/> ' + 'Refer the AuditHistory.txt attachment for related parent record ids.';
            ahAttachment.setFileName('AuditHistory.txt');
            ahAttachment.setBody(Blob.valueOf(JSON.serialize(ahParentRecordIdMap)));
            attachments.add(ahAttachment);
        } else {
            body += '<br/> No Audit History processing happened.';
        }

        if(attachments.size() > 0) {
            mail.setFileAttachments(attachments);
        }

        mail.setHtmlBody(body);

        mails.add(mail);
        //Added to fix test failing
        if(!test.isRunningTest()) {
            Messaging.sendEmail(mails);
        }
    }

    /*
    * @Method       : createAuditHistoryRecords.
    * @Description  : To create Audit History Records.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : List<SObject> lstRecords.
    */
    public void createAuditHistoryRecords(List<SObject> lstRecords) {
        List<CMPL123__Audit_Trail_Entry__c> lstAuditEntry= new List<CMPL123__Audit_Trail_Entry__c>();

        for(SObject obj : lstRecords) {
            CMPL123__Audit_Trail_Entry__c audEntr = new CMPL123__Audit_Trail_Entry__c();
            audEntr.CMPL123__Action__c = 'Insert';
            audEntr.CMPL123__ParentId__c = '' + obj.Id;
            audEntr.CMPL123__Field_Name__c = 'Name';
            audEntr.CMPL123__Object_Name__c = objectApiName;
            audEntr.CMPL123__Object_Api_Name__c = objectApiName;
            audEntr.CMPL123__OldValue__c = null;
            audEntr.CMPL123__NewValue__c = 'Reopen by DCR Process';
            //Added to fix defect #1437, 1438
            audEntr.CMPL123__Audit_Trail_JSON__c = '[{"ov":"","objectAPI":"","nv":"Reopen by DCR Process","lookupAPI":"","fn":"Name","fieldAPI":"Name"}]';

            lstAuditEntry.add(audEntr);
        }

        if(lstAuditEntry.size() > 0) {
            integer ahIndex = 0;
            String errMessage = '';
            for (Database.SaveResult sr : Database.insert(lstAuditEntry, false)) {
                errMessage = '';
                if(sr.success) {
                    ahParentRecordIdMap.put(lstAuditEntry[ahIndex].CMPL123__ParentId__c, 'Created Audit history - ' + sr.getId());
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        errMessage += err.getMessage();
                    }
                    ahParentRecordIdMap.put(lstAuditEntry[ahIndex].CMPL123__ParentId__c, errMessage);
                }
                ahIndex++;
            }
        }
    }
}