/*
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : ProcessMigratedRecords.
* @Why   : Process Migrated Records.
* @When  : 22-JAN-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 22-JAN-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 15-JUN-2020         Code Audit                        Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 16-JUN-2020         Defect #101.1                     Removed hardcoded emails.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 18-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class ProcessMigratedRecords implements Database.Batchable<sObject>, Database.Stateful {
    String objectApiName, userName, statusApiName, ruleApiName;
    Set<Id> recordIds = new Set<Id>();  // MR - 23MAY19 - Added for processing selected records
    Id userId;
    Date migrationDate;
    boolean auditOnlyFlag = false;
    Map<Id, String> wfhParentRecordIdMap = new Map<Id, String>();
    Map<Id, String> ahParentRecordIdMap = new Map<Id, String>();
    Integer numberOfAHErrorRecords = 0;
    Integer numberOfAHSuccessRecords = 0;
    Integer numberOfWHErrorRecords = 0;
    Integer numberOfWHSuccessRecords = 0;

    /*
    * @Method       : ProcessMigratedRecords Constructor.
    * @Description  : To handle  the logic in Process Migrated Records.
    * @Invoke       : Events from ProcessMigratedRecords.
    * @Return       : N/A.
    * @Params       : String objectApiName.
    */
    public ProcessMigratedRecords(String objectApiName){
        this.objectApiName = objectApiName;
        userId = [SELECT id, Name, Email FROM User WHERE Username = :Label.Migration_User_Name].Id;

        migrationDate = Date.parse(Label.Migration_Start_Date);

    }

    /*
    * @Method       : ProcessMigratedRecords Constructor.
    * @Description  : For processing selected records.
    * @Invoke       : N/A.
    * @Return       : N/A
    * @Params       : String objectApiName, Set<Id> inpRecordIds
    */
    // MR - 23MAY19 - Added for processing selected records
    public ProcessMigratedRecords(String objectApiName, Set<Id> inpRecordIds) {
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
        String whereClause = ' WHERE LastModifiedById = :userId AND SystemModStamp >= :migrationDate';
        if(this.recordIds.size() > 0) { whereClause = ' WHERE Id IN :recordIds'; }       // MR - 23MAY19 - Added for processing selected records
        if(objectApiName.equals('CMPL123CME__Complaint__c')) {
            query = 'SELECT Id, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__CMPL123_WF_Action__c, CreatedById, CMPL123Rule_Key_Value__c, Ticket_Type__c FROM ' + objectApiName + whereClause;
        } else if(objectApiName.equals('CMPL123CME__EMDR__c')) {
            query = 'SELECT Id, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__CMPL123_WF_Action__c, CreatedById, CMPL123CME__CMPL123Rule_Key_Value__c FROM ' + objectApiName + whereClause;
        } else if(objectApiName.equals('Product_Lot__c') || objectApiName.equals('Product_Ticket__c') || objectApiName.equals('Trend_Item_Issue_Code__c')
                  || objectApiName.equals('CMPL123__Product__c') || objectApiName.equals('Attachment__c') || objectApiName.equals('Account') ) {
                      auditOnlyFlag = true;
                      query = 'SELECT Id, CreatedById FROM ' + objectApiName + whereClause;
                  } else {
                      query = 'SELECT Id, CMPL123_WF_Status__c, CMPL123_WF_Action__c, CreatedById, CMPL123Rule_Key_Value__c FROM ' + objectApiName + whereClause;
                  }
        return Database.getQueryLocator(query);
    }

    /*
    * @Method       : execute.
    * @Description  : To handle execute.
    * @Invoke       : Events from ProcessMigratedRecords.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC, List<SObject> lstRecords
    */
    global void execute(Database.BatchableContext BC, List<SObject> lstRecords) {
        System.debug('=======lstRecords======='+JSON.serialize(lstRecords));
        Map<Id, SObject> wfhObjectRecordsMap = new Map<Id, SObject>();
        Map<Id, SObject> ahObjectRecordsMap = new Map<Id, SObject>();
        Map<String,CMPL123__WF_Step__c> mapWFStepWithRuleKey = New Map<String,CMPL123__WF_Step__c>();
        Set<String> setWfStatus = new Set<String>();
        Set<String> setWFRuleKeyValue = new  Set<String>();

        statusApiName = ((objectApiName == 'CMPL123CME__Complaint__c' || objectApiName == 'CMPL123CME__EMDR__c') ? 'CMPL123CME__': '') + 'CMPL123_WF_Status__c';
        ruleApiName = (objectApiName == 'CMPL123CME__EMDR__c' ? 'CMPL123CME__': '') + 'CMPL123Rule_Key_Value__c';
        for(SObject obj : lstRecords) {
            ahObjectRecordsMap.put(obj.id, obj);

            if(!auditOnlyFlag) {
                wfhObjectRecordsMap.put(obj.id, obj);

                setWfStatus.add(String.valueOf(obj.get(statusApiName)));
                setWFRuleKeyValue.add(String.valueOf(obj.get(ruleApiName)));
            }
        }
        if(!auditOnlyFlag) {
            for(CMPL123__WF_Step__c objWFStep : [SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name, CMPL123__WF_Rule__r.CMPL123__Target_Object__c,
                                                 CMPL123__WF_Rule__r.CMPL123__Record_Type__c, CMPL123__Start_Status__r.Name
                                                 FROM CMPL123__WF_Step__c
                                                 WHERE (CMPL123__End_Status__r.Name IN :setWfStatus) AND
                                                 CMPL123__WF_Rule__r.CMPL123__Record_Type__c IN :setWFRuleKeyValue AND
                                                 CMPL123__WF_Rule__r.CMPL123__Is_Active__c = true]) {
                                                     mapWFStepWithRuleKey.put((objWFStep.CMPL123__End_Status__r.Name + '-' + objWFStep.CMPL123__WF_Rule__r.CMPL123__Record_Type__c).toLowerCase(), objWFStep);
                                                 }
            // Remove the records which has WF History record
            for(CMPL123__WF_History__c wfHistoryRecord : [SELECT Id, Name, CMPL123__Related_Id__c
                                                          FROM CMPL123__WF_History__c
                                                          WHERE CMPL123__Related_Id__c IN :wfhObjectRecordsMap.keySet()]) {
                                                              wfhObjectRecordsMap.remove(wfHistoryRecord.CMPL123__Related_Id__c);
                                                          }
            if(wfhObjectRecordsMap.size() > 0) {
                createWFHistoryRecords(wfhObjectRecordsMap.values(), mapWFStepWithRuleKey);
            }
        }
        // Remove the records which has Audit History record
        for(CMPL123__Audit_Trail_Entry__c auditHistoryRecord : [SELECT Id, Name, CMPL123__ParentId__c
                                                                FROM CMPL123__Audit_Trail_Entry__c
                                                                WHERE CMPL123__ParentId__c IN :ahObjectRecordsMap.keySet()]) {
                                                                    ahObjectRecordsMap.remove(auditHistoryRecord.CMPL123__ParentId__c);
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
        List<String> emailNotifierAddress = String.valueOf(Label.Migration_Email_Notifier).split(',');
        mail.setToAddresses(emailNotifierAddress);
        mail.setSubject('Batch Processing for ' + objectApiName + ' on ' + System.today());
        String body = 'Summary of the processing happened for ' + objectApiName + '<br/>';

        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment wfhAttachment = new Messaging.EmailFileAttachment();
        Messaging.EmailFileAttachment ahAttachment = new Messaging.EmailFileAttachment();

        if(wfhParentRecordIdMap.size() > 0) {
            // 13FEB To Resolve to Heap Size Issue
            //body += '<br/> ' + wfhParentRecordIdMap.size() + ' number of records for which Workflow History processing completed.';
            body += '<br/> ' + numberOfWHSuccessRecords + ' number of records for which Workflow History processing completed.';
            body += '<br/> ' + numberOfWHErrorRecords + ' number of records for which Workflow History processing failed.';
            body += '<br/> ' + 'Refer the WFHistory.txt attachment for related parent record ids.';

            wfhAttachment.setFileName('WFHistory.txt');
            wfhAttachment.setBody(Blob.valueOf(JSON.serialize(wfhParentRecordIdMap)));
            attachments.add(wfhAttachment);
        } else {
            body += '<br/> No Workflow History processing happened.';
        }

        if(ahParentRecordIdMap.size() > 0) {
            // 13FEB To Resolve to Heap Size Issue
            //body += '<br/> ' + ahParentRecordIdMap.size() + ' number of records for which Audit History processing completed.';
            body += '<br/> ' + numberOfAHSuccessRecords + ' number of records for which Audit History processing completed.';
            body += '<br/> ' + numberOfAHErrorRecords + ' number of records for which Audit History processing failed.';
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
        Messaging.sendEmail(mails);
    }

    /*
    * @Method       : createWFHistoryRecords.
    * @Description  : To handle  create Workflow History Records.
    * @Invoke       : Events from createWFHistoryRecords.
    * @Return       : N/A.
    * @Params       : List<SObject> lstRecords,Map<String,CMPL123__WF_Step__c> mapWFStepWithRuleKey.
    */
    public void createWFHistoryRecords(List<SObject> lstRecords, Map<String,CMPL123__WF_Step__c> mapWFStepWithRuleKey) {

        if(mapWFStepWithRuleKey.isEmpty()) {
            return;
        }

        List<CMPL123__WF_History__c>  workflowHistoryList = new List<CMPL123__WF_History__c>();
        String keyStr = '';
        for(SObject obj : lstRecords) {
            keyStr = (String.valueOf(obj.get(statusApiName)) + '-' + String.valueOf(obj.get(ruleApiName))).toLowerCase();
            if(mapWFStepWithRuleKey.containsKey(keyStr)) {
                CMPL123__WF_Step__c wfStep = mapWFStepWithRuleKey.get(keyStr);
                CMPL123__WF_History__c wfh = new CMPL123__WF_History__c(CMPL123__Status__c = String.valueOf(obj.get(statusApiName)),
                                                                        CMPL123__Action__c = wfStep.CMPL123__Action__r.Name, CMPL123__Workflow_Step__c = wfStep.Id,
                                                                        CMPL123__Related_Id__c = obj.Id);
                workflowHistoryList.add(wfh);
            }
        }
        if(workflowHistoryList.size() > 0) {
            integer wfhIndex = 0;
            String errMessage = '';
            for (Database.SaveResult sr : Database.insert(workflowHistoryList, false)) {
                errMessage = '';
                if(sr.success) {
                    if(wfhParentRecordIdMap.size() > 90000){
                        numberOfWHSuccessRecords = numberOfWHSuccessRecords + 1;
                    }else{
                        wfhParentRecordIdMap.put(workflowHistoryList[wfhIndex].CMPL123__Related_Id__c, 'Created WF history - ' + sr.getId());
                        numberOfWHSuccessRecords = numberOfWHSuccessRecords + 1;
                    }

                } else {
                    for(Database.Error err : sr.getErrors()) {
                        errMessage += err.getMessage();
                    }
                    if(wfhParentRecordIdMap.size() > 90000){
                        numberOfWHErrorRecords = numberOfWHErrorRecords + 1;
                    }else{
                        wfhParentRecordIdMap.put(workflowHistoryList[wfhIndex].CMPL123__Related_Id__c, errMessage);
                        numberOfWHErrorRecords = numberOfWHErrorRecords + 1;
                    }
                }
                wfhIndex++;
            }
        }
    }

    /*
    * @Method       : createAuditHistoryRecords.
    * @Description  : Create Audit History Records.
    * @Invoke       : Events from createAuditHistoryRecords.
    * @Return       : N/A.
    * @Params       : List<SObject> lstRecords.
    */
    public void createAuditHistoryRecords(List<SObject> lstRecords) {
        List<CMPL123__Audit_Trail_Entry__c> lstAuditEntry= new List<CMPL123__Audit_Trail_Entry__c>();
        System.debug('=======Creating Audit History ======='+JSON.serialize(lstRecords));
        for(SObject obj : lstRecords) {
            CMPL123__Audit_Trail_Entry__c audEntr = new CMPL123__Audit_Trail_Entry__c();
            audEntr.CMPL123__Action__c = 'Insert';
            audEntr.CMPL123__ParentId__c = '' + obj.Id;
            audEntr.CMPL123__Field_Name__c = 'Name';
            audEntr.CMPL123__Object_Name__c = objectApiName;
            audEntr.CMPL123__Object_Api_Name__c = objectApiName;
            audEntr.CMPL123__OldValue__c = null;
            audEntr.CMPL123__NewValue__c = 'Migration from Legacy System';
            //Added to fix defect #1437, 1438
            audEntr.CMPL123__Audit_Trail_JSON__c = '[{"ov":"","objectAPI":"","nv":"Migration from Legacy System","lookupAPI":"","fn":"Name","fieldAPI":"Name"}]';
            lstAuditEntry.add(audEntr);
        }

        if(lstAuditEntry.size() > 0) {
            integer ahIndex = 0;
            String errMessage = '';
            for (Database.SaveResult sr : Database.insert(lstAuditEntry, false)) {
                errMessage = '';
                if(sr.success) {
                    if(ahParentRecordIdMap.size() > 90000){
                        numberOfAHSuccessRecords = numberOfAHSuccessRecords+1;
                    }else{
                        ahParentRecordIdMap.put(lstAuditEntry[ahIndex].CMPL123__ParentId__c, 'Created Audit history - ' + sr.getId());
                        numberOfAHSuccessRecords = numberOfAHSuccessRecords+1;
                    }

                } else {
                    for(Database.Error err : sr.getErrors()) {
                        errMessage += err.getMessage();
                    }
                    if(ahParentRecordIdMap.size() > 90000){
                        numberOfAHErrorRecords = numberOfAHErrorRecords + 1;
                    }else{
                        ahParentRecordIdMap.put(lstAuditEntry[ahIndex].CMPL123__ParentId__c, errMessage);
                        numberOfAHErrorRecords = numberOfAHErrorRecords + 1;
                    }

                }
                ahIndex++;
            }
        }
    }
}