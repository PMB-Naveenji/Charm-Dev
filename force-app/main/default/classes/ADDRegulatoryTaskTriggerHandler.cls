/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2020  Sparta Systems, Inc.
* @What  : ADDRegulatoryTaskTriggerHandler
* @Why   : Handles all the customization involved on Regulatory Task object.
* @When  : 03-05-2020
* @Where : From Regulatory_Task_AuditTrigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID        Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    03-05-2020             Def #1 fix             Adjusted in order to send correct email based on record type
                                                                           and action(only for Regulatory Opinion Task).
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit             Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    09-06-2020             #123/CHARM-2729        Added updateMDILastModifiedDate method.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit             Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    13-JAN-2021            TWD Upgrade            Moved Prod Eval SF WF Rules into apex. Added beforeInsertEvent,
*                                                                          beforeInsertOrUpdateEvent methods and their invocation.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Lakshman                 01-JUL-2021            MIR Project            The system shall auto promote a MIR record from �Pending 
                                                                           Regulatory Decision� to �Pending Final Review� status.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Varsha Hariharan         05-JUL-2021            Charm Release 2       The system shall send E-Mail to the Vigilance Contacts of MIR  
*                                                                          record when Competent Authority, Notified Body or Regulatory 
*                                                                           Opinion task is submitted.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Larry Resnik             07-SEP-2021            CHaRM Release 2        Fixed an unformatted string in the Regulatory Task Opinion 
*                                                                          email body.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ADDRegulatoryTaskTriggerHandler extends TriggerHandler {

    //Added on 2/21/2020 and related to FRS-1510-08 implementation
    static Id notifiedBodyRegulatoryResponseRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName()
                .get('Notified Body Regulatory Response').getRecordTypeId();
    static Id competentAuthorityRegulatoryResponseRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName()
                .get('Competent Authority Regulatory Response').getRecordTypeId();
    static Id regulatoryOpinionTaskRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName()
                .get('Regulatory Opinion Task').getRecordTypeId();
    static Map<Integer, String> monthNameMap = new Map<Integer, String>{
                1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr', 5 => 'May',
                6 => 'Jun', 7 => 'Jul', 8 => 'Aug', 9 => 'Sep', 10 => 'Oct',
                11 => 'Nov', 12 => 'Dec'
        };
    static String competentAuthorityOrNotifiedBody = 'Regulatory_Task_Notification_when_Record_Type_Competent_Authority_or_Notified_Bo';
    static String regulatoryOpinion = 'Regulatory_Task_Notification_when_Record_Type_Regulatory_Opinion_Task';
    //Varsha Hariharan - Changes for FRS-1515-08
    static String competentAuthorityOrNotifiedMIR = 'Regulatory_Task_Notification_when_Record_Type_Competent_Or_Notified';
    static String regulatoryOpinionTaskMIR = 'Regulatory_Task_Notification_when_Record_Type_Regulatory_Opinion';
    static Boolean isEmailsSent = false;

    /*
    Description : public method to handle all the logic in before insert event
    */
    public override void beforeInsert() {
        vigilanceContactwithPrimaryContact();
        beforeInsertEvent();
        beforeInsertOrUpdateEvent();
    }

    /*
    Description : public method to handle all the logic in after insert event
    */
    public override void afterInsert() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        vigilanceBackupContactEmails();
    }

    /*
    Description : public method to handle all the logic in before update event
    */
    public override void beforeUpdate() {

        //Added on : 14-03-2019 to Clear Task_Item_Completion_Date__c on re-open 
        List< Regulatory_Task__c > newRegTasks = (List< Regulatory_Task__c >) Trigger.New;
        Map<Id, Regulatory_Task__c > oldRegTaskMap = (Map<Id, Regulatory_Task__c >) Trigger.oldMap;
        Map<Id, Regulatory_Task__c > newRegTaskMap = (Map<Id, Regulatory_Task__c >) Trigger.newMap;

        for (Regulatory_Task__c task : newRegTasks) {

            if (task.CMPL123_WF_Action__c == 'Reopen' && oldRegTaskMap != null && oldRegTaskMap.containsKey(task.Id) && task.CMPL123_WF_Action__c != oldRegTaskMap.get(task.Id).CMPL123_WF_Action__c) {
                task.Task_Item_Completion_Date__c = null;
            }
        }
        vigilanceContactwithPrimaryContact();
        setReopenRationale(newRegTaskMap, oldRegTaskMap);        
        beforeInsertOrUpdateEvent();        
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    Description : public method to handle all the logic in after insert event
    */
    public override void afterUpdate() {
        //code which invokes 123Compliance platform audit and workflow code

        List< Regulatory_Task__c > newRegTasks = (List< Regulatory_Task__c >) Trigger.New;
        Map<Id, Regulatory_Task__c > oldRegTaskMap = (Map<Id, Regulatory_Task__c >) Trigger.oldMap;
        Set<String> medDevIds = new Set<String>();
        Set<String> euMirIds = new Set<String>();//@Lakshman:Changes for FRS-1515-13
        Set<Id> taskIds = new Set<Id>();
        Set<Id> submittedRegOpinionTask = new Set<Id>();

        for (Regulatory_Task__c task : newRegTasks) { //@Lakshman:Changes for FRS-1515-13
            if ((task.CMPL123_WF_Status__c == 'Closed-Done' || task.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Voided) && oldRegTaskMap != null && task.CMPL123_WF_Status__c != oldRegTaskMap.get(task.Id).CMPL123_WF_Status__c) {
                        if(task.MDI__c !=null){
                            medDevIds.add(task.MDI__c);  
                        }
                        if(task.EU_MIR__c !=null){
                            euMirIds.add(task.EU_MIR__c);
                        }
                        taskIds.add(task.Id);
                }
            
            if (null != oldRegTaskMap && task.recordTypeId == regulatoryOpinionTaskRTID
                && task.CMPL123_WF_Action__c == 'Submit' 
                && oldRegTaskMap.get(task.Id).CMPL123_WF_Action__c != task.CMPL123_WF_Action__c) {
                submittedRegOpinionTask.add(task.Id);
            }
        }
        if (medDevIds.size() > 0) {
            List<CMPL123CME__MEDDEV__c> updatableMedDevs = new List<CMPL123CME__MEDDEV__c>();
            for (CMPL123CME__MEDDEV__c medDev : [
                    SELECT Id, (
                            SELECT Id
                            FROM Regulatory_Tasks__r
                            WHERE
                            CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c !=: AspenConstants.STR_Closed_Voided AND ID NOT IN:taskIds
                    )
                    FROM
                            CMPL123CME__MEDDEV__c
                    WHERE Id IN:medDevIds AND CMPL123_WF_Status__c = 'Pending Regulatory Decision'
            ]) {
                if (medDev.Regulatory_Tasks__r.size() == 0) {
                    updatableMedDevs.add(
                            new CMPL123CME__MEDDEV__c(
                                    Id = medDev.Id,
                                    CMPL123Task_Key_Value__c = 'CompleteRegulatoryResponse'
                            )
                    );
                }
            }
            if (updatableMedDevs.size() > 0) {
                update updatableMedDevs;
            }
        }
        //@Lakshman:Changes for FRS-1515-13
        if (euMirIds.size() > 0) {
            List<CMPL123CME__EU_MIR__c> updatableEuMirs = new List<CMPL123CME__EU_MIR__c>();
            for(CMPL123CME__EU_MIR__c euMir : [SELECT Id,(SELECT Id FROM Regulatory_Tasks__r WHERE 
                                                          CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c !=: AspenConstants.STR_Closed_Voided AND ID NOT IN: taskIds) FROM 
                                               CMPL123CME__EU_MIR__c WHERE Id IN: euMirIds AND CMPL123_WF_Status__c = 'Pending Regulatory Decision']){
                                                   if(euMir.Regulatory_Tasks__r.size() == 0) {
                                                       updatableEuMirs.add(
                                                           new CMPL123CME__EU_MIR__c(
                                                               Id = euMir.Id,
                                                               CMPL123Task_Key_Value__c = 'EUMIRCompleteRegulatoryResponse'
                                                           )
                                                       );
                                                   }
                                               }
            if (updatableEuMirs.size() > 0) {
                update updatableEuMirs;
            }
        }
        
        if (submittedRegOpinionTask.size() > 0 && !isEmailsSent) {
             vigilanceBackupContactEmails();        
        }
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    Description : public method to handle all the logic in before delete event
    */
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /**
    * @Method       : vigilanceContactwithPrimaryContact
    * @Description  : W-000125 - Vigilance Contact field should be assigned only to users 
    with in Country.Primary Vigilance Contact and Country.Backup Vigilance Contact related list
    * @Return       : N/A
    * @Params       : Trigger Context
    **/
    private static void vigilanceContactwithPrimaryContact() {
        Map<Id, Id> mapRegulatoryTaskCountryIds = New Map<Id, Id>();
        Map<Id, Set<Id>> mapCountryContactIds = New Map<Id, Set<Id>>();
        Map<Id, Set<String>> mapCountryContactNames = New Map<Id, Set<String>>();

        for (Regulatory_Task__c objRegulatoryTask : (List<Regulatory_Task__c>) Trigger.New) {
            if (objRegulatoryTask.Country_Id__c != null && objRegulatoryTask.Assignee_Name__c != null) {
                mapRegulatoryTaskCountryIds.put(objRegulatoryTask.Id, objRegulatoryTask.Country_Id__c);
            }
        }

        if (!mapRegulatoryTaskCountryIds.isEmpty()) {
            for (Country__c objCountry : [
                    SELECT Id, Name, Primary_Vigilance_Contact__c, Primary_Vigilance_Contact__r.Name, (
                            SELECT Country_Backup_Vigilance_Contact_Name__c,Country_Backup_Vigilance_Contact_Name__r.Name
                            FROM Country_Backup_Vigilance_Contacts__r
                            WHERE Country_Backup_Vigilance_Contact_Name__c != null
                    )
                    FROM Country__c
                    WHERE Id IN:mapRegulatoryTaskCountryIds.values()
            ]) {
                mapCountryContactIds.put(objCountry.Id, New Set<Id>());
                mapCountryContactNames.put(objCountry.Id, New Set<String>());

                if (objCountry.Primary_Vigilance_Contact__c != null) {
                    mapCountryContactIds.get(objCountry.Id).add(objCountry.Primary_Vigilance_Contact__c);
                    mapCountryContactNames.get(objCountry.Id).add(objCountry.Primary_Vigilance_Contact__r.Name);
                }

                for (Country_Backup_Vigilance_Contact__c objCountryBackupVigilanceContact : objCountry.Country_Backup_Vigilance_Contacts__r) {
                    mapCountryContactIds.get(objCountry.Id).add(objCountryBackupVigilanceContact.Country_Backup_Vigilance_Contact_Name__c);
                    mapCountryContactNames.get(objCountry.Id).add(objCountryBackupVigilanceContact.Country_Backup_Vigilance_Contact_Name__r.Name);
                }
            }
        }

        if (!mapCountryContactIds.isEmpty() && !mapCountryContactIds.values().isEmpty()) {
            for (Regulatory_Task__c objRegulatoryTask : (List<Regulatory_Task__c>) Trigger.New) {
                if (objRegulatoryTask.Assignee_Name__c != null
                        && mapCountryContactIds.get(mapRegulatoryTaskCountryIds.get(objRegulatoryTask.Id)) != null
                        && !mapCountryContactIds.get(mapRegulatoryTaskCountryIds.get(objRegulatoryTask.Id)).contains(objRegulatoryTask.Assignee_Name__c)) {

                    objRegulatoryTask.addError(Label.Regulatory_Task_Vigilance_Contact + ' '
                            + JSON.serialize(mapCountryContactNames.get(mapRegulatoryTaskCountryIds.get(objRegulatoryTask.Id))));
                }
            }
        }

        if (Trigger.isInsert) {
            for (Regulatory_Task__c objRegulatoryTask : (List<Regulatory_Task__c>) Trigger.New) {
                if (objRegulatoryTask.Assignee_Name__c == null && objRegulatoryTask.Vigilance_Contact_Formula__c != null) {
                    objRegulatoryTask.Assignee_Name__c = objRegulatoryTask.Vigilance_Contact_Formula__c;
                }
            }
        }

    }

    /**
    * @Method       : vigilanceBackupContactEmails
    * @Description  : W-000207 - 799 / (MDI) Email should be sent to all the users in the 
    Country - Backup Vigilance Contacts related to the Country.
    * @Return       : N/A
    * @Params       : Trigger Context
    **/
    private static void vigilanceBackupContactEmails() {
        Map<Id, List<Regulatory_Task__c>> mapCountryContactIds = New Map<Id, List<Regulatory_Task__c>>();
        for (Regulatory_Task__c objRegulatoryTask : (List<Regulatory_Task__c>) Trigger.New) {
            if (objRegulatoryTask.Country_Id__c != null && ((Trigger.isInsert
                    && (notifiedBodyRegulatoryResponseRTID == objRegulatoryTask.recordTypeId
                    || competentAuthorityRegulatoryResponseRTID == objRegulatoryTask.recordTypeId))
                    || (Trigger.isUpdate && regulatoryOpinionTaskRTID == objRegulatoryTask.recordTypeId 
                        && objRegulatoryTask.CMPL123_WF_Action__c == 'Submit' // send email upon Submit action on Regulatory Opinion Task
                        && (String)Trigger.oldMap.get(objRegulatoryTask.Id).get('CMPL123_WF_Status__c') != objRegulatoryTask.CMPL123_WF_Action__c))) {
                if (!mapCountryContactIds.containsKey(objRegulatoryTask.Country_Id__c)) {
                    mapCountryContactIds.put(objRegulatoryTask.Country_Id__c, New List<Regulatory_Task__c>{
                            objRegulatoryTask
                    });
                } else {
                    mapCountryContactIds.get(objRegulatoryTask.Country_Id__c).add(objRegulatoryTask);
                }
            }
        }

        if (!mapCountryContactIds.isEmpty()) {
            try {
                Set<String> sendToIds = New Set<String>();
                Map<String, EmailTemplate> templatesByRegType = new Map<String, EmailTemplate>();

                for (EmailTemplate objEmailTemplate : [SELECT Id, Body, DeveloperName, Subject FROM EmailTemplate
                            WHERE DeveloperName IN (:competentAuthorityOrNotifiedBody, :regulatoryOpinion, :competentAuthorityOrNotifiedMIR, :regulatoryOpinionTaskMIR)]) { // pick up email templates
                    if (objEmailTemplate.DeveloperName == competentAuthorityOrNotifiedBody) {
                        templatesByRegType.put(notifiedBodyRegulatoryResponseRTID, objEmailTemplate);
                        templatesByRegType.put(competentAuthorityRegulatoryResponseRTID, objEmailTemplate);
                    } else if (objEmailTemplate.DeveloperName == regulatoryOpinion) {
                        templatesByRegType.put(regulatoryOpinionTaskRTID, objEmailTemplate);
                    } else if (objEmailTemplate.DeveloperName == competentAuthorityOrNotifiedMIR) {
                        templatesByRegType.put(competentAuthorityRegulatoryResponseRTID+'MIR', objEmailTemplate);
                        templatesByRegType.put(notifiedBodyRegulatoryResponseRTID+'MIR', objEmailTemplate);
                    } else if (objEmailTemplate.DeveloperName == regulatoryOpinionTaskMIR) {
                        templatesByRegType.put(regulatoryOpinionTaskRTID+'MIR', objEmailTemplate);
                    }
                }
                
                String recordURL = System.Url.getSalesforceBaseUrl().toExternalForm();
                List<Messaging.SingleEmailMessage> lstSingleEmailMessages = new List<Messaging.SingleEmailMessage>();
                for (Regulatory_Task__c objRegulatoryTask : (List<Regulatory_Task__c>) Trigger.New) {
                    String identifier = objRegulatoryTask.Assignee_Name__c + (String) objRegulatoryTask.Id; 
                    Id sendTo = objRegulatoryTask.Assignee_Name__c;
                    //Varsha Hariharan - Changes for FRS-1515-08 Added condition
                    if (sendTo != null && !sendToIds.contains(identifier) // avoid duplicate emails
                            && (notifiedBodyRegulatoryResponseRTID == objRegulatoryTask.recordTypeId
                            || competentAuthorityRegulatoryResponseRTID == objRegulatoryTask.recordTypeId
                            || regulatoryOpinionTaskRTID == objRegulatoryTask.recordTypeId)
                            && objRegulatoryTask.MDI__c != null
                            ) {
                        Messaging.SingleEmailMessage mail = createAndFillInEmail(objRegulatoryTask,
                            objRegulatoryTask.Assignee_Name__c, recordURL, templatesByRegType.get(objRegulatoryTask.RecordTypeId));
                        lstSingleEmailMessages.add(mail);
                        sendToIds.add(identifier);
                    }
                    if (sendTo != null && !sendToIds.contains(identifier) // avoid duplicate emails
                            && (notifiedBodyRegulatoryResponseRTID == objRegulatoryTask.recordTypeId
                            || competentAuthorityRegulatoryResponseRTID == objRegulatoryTask.recordTypeId
                            || regulatoryOpinionTaskRTID == objRegulatoryTask.recordTypeId)
                            && objRegulatoryTask.EU_MIR__c != null
                            ) {
                        Messaging.SingleEmailMessage mail = createAndFillInEmail(objRegulatoryTask,
                            objRegulatoryTask.Assignee_Name__c, recordURL, templatesByRegType.get(objRegulatoryTask.RecordTypeId+'MIR'));
                        lstSingleEmailMessages.add(mail);
                        sendToIds.add(identifier);
                    }
                }
                for (Country__c objCountry : [SELECT Id,Primary_Vigilance_Contact__c,
                                              (SELECT Id, Country_Backup_Vigilance_Contact_Name__c, Country_Backup_Vigilance_Contact_Name__r.Name 
                                               FROM Country_Backup_Vigilance_Contacts__r)
                                              FROM Country__c WHERE Id IN:mapCountryContactIds.keySet()]) {
                                                  
                                                  for (Country_Backup_Vigilance_Contact__c objCountryBackupVigilanceContact : objCountry.Country_Backup_Vigilance_Contacts__r) {
                                                      if (null != objCountryBackupVigilanceContact.Country_Backup_Vigilance_Contact_Name__r.Name){
                                                          for (Regulatory_Task__c objRegulatoryTask : mapCountryContactIds.get(objCountry.Id)) {
                                                              String identifier = objCountryBackupVigilanceContact.Country_Backup_Vigilance_Contact_Name__r.Name + (String) objRegulatoryTask.Id;
                                                              //Changes for FRS-1515-08 - Added condition - Varsha Hariharan
                                                              if (!sendToIds.contains(identifier) && objRegulatoryTask.MDI__c != null) { // avoid duplicate emails
                                                                  Messaging.SingleEmailMessage mail = createAndFillInEmail(objRegulatoryTask,
                                                                                                                           objCountryBackupVigilanceContact.Country_Backup_Vigilance_Contact_Name__c,
                                                                                                                           recordURL, templatesByRegType.get(objRegulatoryTask.RecordTypeId));
                                                                  lstSingleEmailMessages.add(mail);
                                                                  sendToIds.add(identifier);
                                                              }
                                                              //Changes for FRS-1515-08 - EU MIR Mail triggering logic - Varsha Hariharan
                                                              if (!sendToIds.contains(identifier) && objRegulatoryTask.EU_MIR__c != null) { // avoid duplicate emails
                                                                  Messaging.SingleEmailMessage mail = createAndFillInEmail(objRegulatoryTask,
                                                                                                                           objCountryBackupVigilanceContact.Country_Backup_Vigilance_Contact_Name__c,
                                                                                                                           recordURL, templatesByRegType.get(objRegulatoryTask.RecordTypeId+'MIR'));
                                                                  lstSingleEmailMessages.add(mail);
                                                                  sendToIds.add(identifier);
                                                              }
                                                              identifier = objCountry.Primary_Vigilance_Contact__c + (String) objRegulatoryTask.Id;
                                                              //Changes for FRS-1515-08 - Added condition - Varsha Hariharan
                                                              if (!sendToIds.contains(identifier) && objRegulatoryTask.MDI__c != null) { // avoid duplicate emails
                                                                  Messaging.SingleEmailMessage mail2 = createAndFillInEmail(objRegulatoryTask,
                                                                                                                            objCountry.Primary_Vigilance_Contact__c, recordURL, templatesByRegType.get(objRegulatoryTask.RecordTypeId));
                                                                  lstSingleEmailMessages.add(mail2);
                                                                  sendToIds.add(identifier);
                                                              }
                                                              //Changes for FRS-1515-08 - EU MIR Mail triggering logic - Varsha Hariharan
                                                              if (!sendToIds.contains(identifier) && objRegulatoryTask.EU_MIR__c != null) { // avoid duplicate emails
                                                                  Messaging.SingleEmailMessage mail2 = createAndFillInEmail(objRegulatoryTask,
                                                                                                                            objCountry.Primary_Vigilance_Contact__c, recordURL, templatesByRegType.get(objRegulatoryTask.RecordTypeId+'MIR'));
                                                                  lstSingleEmailMessages.add(mail2);
                                                                  sendToIds.add(identifier);
                                                              }
                                                          }
                                                      }
                                                  }
                                              }
                if (lstSingleEmailMessages.size() > 0) {
                    List<Messaging.SendEmailResult> results = Messaging.sendEmail(lstSingleEmailMessages);
                    isEmailsSent = true;
                }

            } catch (Exception E) {
                System.debug('Error message: ' + E.getMessage());
            }
        }

    }

    /**
    * @Method       : setReopenRationale
    * @Description  : used to set reopen rationale from workflow history 
    * @Return       : N/A
    * @Params       : Map<Id,Hazard_Assessment__c> newRecordMap, 
    *                 Map<Id,Hazard_Assessment__c> oldRecordMap 
    **/
    public static void setReopenRationale(Map<Id, Regulatory_Task__c> newRecordMap,
            Map<Id, Regulatory_Task__c> oldRecordMap) {
        Regulatory_Task__c oldRecord;
        Regulatory_Task__c newRecord;
        if (newRecordMap.keyset().size() == 1) {
            for (Regulatory_Task__c sobj : newRecordMap.values()) {
                newRecord = sobj;
                oldRecord = oldRecordMap.get(sobj.Id);
            }
            if (newRecord.CMPL123_WF_Action__c != null && newRecord.CMPL123_WF_Action__c.containsIgnorecase('Reopen')
                    && newRecord.CMPL123_WF_Action__c != oldRecord.CMPL123_WF_Action__c) {
                newRecord.Reopen_Rationale__c = ADDUtil.fetchReopenWorkflowHistory(newRecord.Id);
            }
        }
    }

    //Added on 2/21/2020 and related to FRS-1510-08 implementation
    /**
    * @Method       : createAndFillInCompAutorityOrNotifiedBodyEmail
    * @Description  : used create and fill in email for the Competent Authority/Notified Body
    * @Return       : N/A
    * @Params       : Regulatory_Task__c objRegulatoryTask,
                    Id sendTo,
                    String recordURL,
                    EmailTemplate objEmailTemplate
    **/
    public static Messaging.SingleEmailMessage createAndFillInEmail(
        Regulatory_Task__c objRegulatoryTask,
        Id sendTo, String recordURL, EmailTemplate objEmailTemplate
    ) {
        String strBody = objEmailTemplate.Body;
        //Varsha Hariharan - Defect#147
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if (objEmailTemplate.DeveloperName == competentAuthorityOrNotifiedBody) {
            strBody = strBody.replace('{!Regulatory_Task__c.RecordType}', objRegulatoryTask.RecordTypeId == notifiedBodyRegulatoryResponseRTID
                                        ? 'Notified Body Regulatory Response' : 'Competent Authority Regulatory Response');
            strBody = strBody.replace('{!Regulatory_Task__c.Date__c}', String.valueOf(System.today().day()
                                                                                        + '-' + monthNameMap.get(System.today().month()) + '-' + System.today().year()));
            strBody = strBody.replace('{!Regulatory_Task__c.Country_Of_Origin__c}', objRegulatoryTask.Country_Of_Origin__c);
            strBody = strBody.replace('{!Regulatory_Task__c.MDI_Number_Formula__c}', objRegulatoryTask.MDI_Number_Formula__c);
            // Datetime mdiDueDate = (Datetime)objRegulatoryTask.MdiDue__c;
            
            Integer month = objRegulatoryTask.MDI_Due_Date__c.month();
            Integer year = objRegulatoryTask.MDI_Due_Date__c.year();
            Integer day = objRegulatoryTask.MDI_Due_Date__c.day();
            
            strBody = strBody.replace('{!Regulatory_Task__c.MdiDue__c}', String.valueOf(day + '-' + monthNameMap.get(month) + '-' + year));
            strBody = strBody.replace('{!Regulatory_Task__c.MDI_Commercial_Name_Formula__c}', objRegulatoryTask.MDI_Commercial_Name_Formula__c);
            strBody = strBody.replace('{!Regulatory_Task__c.Name}', objRegulatoryTask.Name);
            strBody = strBody.replace('{!MDI.Link}', recordURL + '/' + objRegulatoryTask.MDI__c);
            strBody = strBody.replace('{!Regulatory_Task__c.Link}', recordURL + '/' + objRegulatoryTask.Id);
            strBody = strBody.replace('\n', '<br/>');
            //Varsha Hariharan - Defect#147
            mail.setSubject(objRegulatoryTask.Email_Subject__c);
        } else if (objEmailTemplate.DeveloperName == regulatoryOpinion) {
            strBody = strBody.replace('{!Regulatory_Task__c.Date__c}', String.valueOf(System.today().day()
                                                                                        + '-' + monthNameMap.get(System.today().month()) + '-' + System.today().year()));
            // Datetime mdiDueDate = (Datetime)objRegulatoryTask.MdiDue__c;
            Integer month = objRegulatoryTask.Due_Date__c.month();
            Integer year = objRegulatoryTask.Due_Date__c.year();
            Integer day = objRegulatoryTask.Due_Date__c.day();
            
            strBody = strBody.replace('{!Regulatory_Task__c.Due_Date__c}', String.valueOf(day + '-' + monthNameMap.get(month) + '-' + year));
            strBody = strBody.replace('{!Regulatory_Task__c.MdiDue__c}', String.valueOf(day + '-' + monthNameMap.get(month) + '-' + year)); // 07-SEP-2021 Larry R: Added
            strBody = strBody.replace('{!Regulatory_Task__c.Name}', objRegulatoryTask.Name);
            strBody = strBody.replace('{!Regulatory_Task__c.Link}', recordURL + '/' + objRegulatoryTask.Id);
            strBody = strBody.replace('\n', '<br/>');
            //Varsha Hariharan - Defect#147
            mail.setSubject(objRegulatoryTask.Email_Subject_Regulatory_Task__c);
        }
        //FRS-1515-08 - Varsha Hariharan - Logic for MIR Email triggering
        else if (objEmailTemplate.DeveloperName == competentAuthorityOrNotifiedMIR) {
            strBody = strBody.replace('{!Regulatory_Task__c.RecordType}', objRegulatoryTask.RecordTypeId == notifiedBodyRegulatoryResponseRTID
                                        ? 'Notified Body Regulatory Response' : 'Competent Authority Regulatory Response');
            strBody = strBody.replace('{!Regulatory_Task__c.Date__c}', String.valueOf(System.today().day()
                                                                                        + '-' + monthNameMap.get(System.today().month()) + '-' + System.today().year()));
            strBody = strBody.replace('{!Regulatory_Task__c.Country_Of_Origin__c}', objRegulatoryTask.Country_Of_Origin__c);
            strBody = strBody.replace('{!Regulatory_Task__c.MDI_Number_Formula__c}', objRegulatoryTask.MDI_Number_Formula__c);
            // Datetime mdiDueDate = (Datetime)objRegulatoryTask.MdiDue__c;
            
            Integer month = objRegulatoryTask.MDI_Due_Date__c.month();
            Integer year = objRegulatoryTask.MDI_Due_Date__c.year();
            Integer day = objRegulatoryTask.MDI_Due_Date__c.day();
            
            strBody = strBody.replace('{!Regulatory_Task__c.MdiDue__c}', String.valueOf(day + '-' + monthNameMap.get(month) + '-' + year));
            strBody = strBody.replace('{!Regulatory_Task__c.MDI_Commercial_Name_Formula__c}', objRegulatoryTask.MDI_Commercial_Name_Formula__c);
            strBody = strBody.replace('{!Regulatory_Task__c.Name}', objRegulatoryTask.Name);
            strBody = strBody.replace('{!MIR.Link}', recordURL + '/' + objRegulatoryTask.EU_MIR__c);
            strBody = strBody.replace('{!Regulatory_Task__c.Link}', recordURL + '/' + objRegulatoryTask.Id);
            //Varsha Hariharan - Defect#147
            strBody = strBody.replace('\n', '<br/>');
            mail.setSubject(objRegulatoryTask.Email_Subject__c);
        } else if (objEmailTemplate.DeveloperName == regulatoryOpinionTaskMIR) {
            strBody = strBody.replace('{!Regulatory_Task__c.Date__c}', String.valueOf(System.today().day()
                                                                                        + '-' + monthNameMap.get(System.today().month()) + '-' + System.today().year()));
            // Datetime mdiDueDate = (Datetime)objRegulatoryTask.MdiDue__c;
            Integer month = objRegulatoryTask.Due_Date__c.month();
            Integer year = objRegulatoryTask.Due_Date__c.year();
            Integer day = objRegulatoryTask.Due_Date__c.day();
            
            strBody = strBody.replace('{!Regulatory_Task__c.Due_Date__c}', String.valueOf(day + '-' + monthNameMap.get(month) + '-' + year));
            strBody = strBody.replace('{!Regulatory_Task__c.Name}', objRegulatoryTask.Name);
            strBody = strBody.replace('{!Regulatory_Task__c.Link}', recordURL + '/' + objRegulatoryTask.Id);
            strBody = strBody.replace('\n', '<br/>');
            //Varsha Hariharan - Defect#147
            mail.setSubject(objRegulatoryTask.Email_Subject_Regulatory_Task__c);
        }
        //mail.setPlainTextBody(strBody);
        mail.setHtmlBody(strBody);
        mail.setTargetObjectId(sendTo);
        mail.setWhatId(objRegulatoryTask.Id);
        mail.setTemplateId(objEmailTemplate.Id);
        mail.setSaveAsActivity(false);
        mail.setUseSignature(false);
        return mail;
    }
    
    /**
    * @Method       : updateMDILastModifiedDate
    * @Invoke       : Events from Trigger after insert/update
    * @Description  : To update parent record "LastModifiedDate" field based on child records
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    // Defect #123/CHARM-2729: added method to update parent MDIs if they weren't updated in current transaction
    public static void updateMDILastModifiedDate() {
        Set<Id> meddevRecordIdSet = new Set<Id>();
        Set<Id> euMirRecordIdSet = new Set<Id>();
        if (!UpdateParentUtility.isMedDevUpdated) {
            UpdateParentUtility.isMedDevUpdated = true;
                for (Regulatory_Task__c regtrytaskCode : (List<Regulatory_Task__c>)Trigger.new){
                    if (regtrytaskCode.MDI__c != null) {
                        meddevRecordIdSet.add(regtrytaskCode.MDI__c);              
                    }
                }
                if (meddevRecordIdSet.size() > 0) { 
                    UpdateParentUtility.isMedDevLastModifDateUpdating = true;              
                    UpdateParentUtility.updateparent_trend(meddevRecordIdSet);
                    UpdateParentUtility.isMedDevLastModifDateUpdating = false;              
                }
        }
        if (!UpdateParentUtility.isEuMirUpdated) {
            UpdateParentUtility.isEuMirUpdated = true;
                for (Regulatory_Task__c regtrytaskCode : (List<Regulatory_Task__c>)Trigger.new){
                    if (regtrytaskCode.EU_MIR__c != null) {
                        euMirRecordIdSet.add(regtrytaskCode.EU_MIR__c);              
                    }
                }
                if (euMirRecordIdSet.size() > 0) { 
                    UpdateParentUtility.isEuMirLastModifDateUpdating = true;              
                    UpdateParentUtility.updateparent_trend(euMirRecordIdSet);
                    UpdateParentUtility.isEuMirLastModifDateUpdating = false;              
                }
        }
    }  
    
    /**
    * @Method       : beforeInsertOrUpdateEvent
    * @Invoke       : Events from Trigger before insert/update
    * @Description  : Contains logic from disabled SF WF Rules
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public void beforeInsertOrUpdateEvent() {
        List< Regulatory_Task__c > newRegTasks = (List< Regulatory_Task__c >) Trigger.New;
        Map<Id, Regulatory_Task__c > oldRegTaskMap = (Map<Id, Regulatory_Task__c >) Trigger.oldMap;
        Set <String> userIds = new Set <String>();
        Set <String> statusesToCheck = new Set <String> {
            'In Progress', 'Closed-Done'
        };
        Set <String> actionsToCheck = new Set <String> {
            'Reopen', 'Submit', 'Void'
        };

        for (Regulatory_Task__c newTask : newRegTasks) {
            Regulatory_Task__c oldTask = oldRegTaskMap?.get(newTask.Id);
            if (actionsToCheck.contains(newTask.CMPL123_WF_Action__c) && newTask.CMPL123_WF_Action_Performed_By__c != null
                    && (Trigger.isInsert || Trigger.isUpdate && newTask.CMPL123_WF_Action__c != oldTask.CMPL123_WF_Action__c)) {
                userIds.add(newTask.CMPL123_WF_Action_Performed_By__c);
            }
        }

        Map<Id, User> userById = new Map <Id, User>();
        if (userIds.size() > 0) {
            userById = new Map <Id, User>(
                [SELECT LastName, FirstName
                    FROM User
                        WHERE Id IN :userIds]);
        }
        
        for (Regulatory_Task__c newTask : newRegTasks) {
            Regulatory_Task__c oldTask = oldRegTaskMap?.get(newTask.Id);
        
            if (statusesToCheck.contains(newTask.CMPL123_WF_Status__c)
                    && (Trigger.isInsert || Trigger.isUpdate && newTask.CMPL123_WF_Status__c != oldTask.CMPL123_WF_Status__c)) {
                switch on newTask.CMPL123_WF_Status__c {
                    when 'In Progress' {   // Autoset Assigned Date WF Rule start
                        newTask.Assigned_Date__c = System.today();
                    }   // Autoset Assigned Date WF Rule end
                    when ('Closed-Done') {   // Autoset Task Item Completion Date WF Rule start
                        newTask.Reopened_By__c = null;
                        newTask.Reopened_On__c = null;
                        newTask.Task_Item_Completion_Date__c = System.now();
                    }   // Autoset Task Item Completion Date WF Rule end
                }
            }

            if (actionsToCheck.contains(newTask.CMPL123_WF_Action__c) && newTask.CMPL123_WF_Action_Performed_By__c != null
                    && (Trigger.isInsert || Trigger.isUpdate && newTask.CMPL123_WF_Action__c != oldTask.CMPL123_WF_Action__c)) {
                
                User performedBy = userById.get(newTask.CMPL123_WF_Action_Performed_By__c);
                switch on newTask.CMPL123_WF_Action__c {
                    when 'Reopen' {   // Workflow - Reopen WF Rule start
                        newTask.Reopened_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newTask.Reopened_On__c = newTask.CMPL123_WF_Action_Performed_On__c;
                    }   // Workflow - Reopen WF Rule end
                    when 'Submit' {   // Workflow - Submit WF Rule start
                        newTask.Submitted_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newTask.Submitted_On__c = newTask.CMPL123_WF_Action_Performed_On__c;
                        newTask.Request_More_Information__c = null;
                    }   // Workflow - Submit WF Rule end
                    when 'Void' {   // Workflow - Void WF Rule start
                        newTask.Voided_By__c = performedBy?.FirstName + ' ' + performedBy?.LastName;
                        newTask.Voided_On__c = newTask.CMPL123_WF_Action_Performed_On__c;
                    }   // Workflow - Void WF Rule end
                }
            }
        }
    }

    /*
    * @Method       : beforeInsertEvent.
    * @Description  : Contains logic from disabled SF WF Rules.
    * @Invoke       : From ADDInvestigationHandler class on before insert events.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void beforeInsertEvent() {
        if (Trigger.isInsert) {
            List< Regulatory_Task__c > newRegTasks = (List< Regulatory_Task__c >) Trigger.New;
            Set <String> mdiIds = new Set<String>();
            Set <String> euMirIds = new Set<String>();
            for (Regulatory_Task__c newTask : newRegTasks) {
                if (newTask.MDI__c != null) {
                    mdiIds.add(newTask.MDI__c);
                }
                if(newTask.EU_MIR__c != null){
                    euMirIds.add(newTask.EU_MIR__c);
                }
            }
            Map <Id, CMPL123CME__MEDDEV__c> MDIs = new Map <Id, CMPL123CME__MEDDEV__c>();
            if (mdiIds.size() > 0) {
                MDIs = new Map <Id, CMPL123CME__MEDDEV__c>(
                    [SELECT CMPL123CME__Complaint__r.RecordType.DeveloperName, CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c,
                        CMPL123CME__Complaint__r.Service_Type__c
                        FROM CMPL123CME__MEDDEV__c 
                            WHERE Id IN :mdiIds]);
            }
            Map <Id, CMPL123CME__EU_MIR__c> MIRs = new Map <Id, CMPL123CME__EU_MIR__c>();
            if (euMirIds.size() > 0) {
                MIRs = new Map <Id, CMPL123CME__EU_MIR__c>(
                    [SELECT CMPL123CME__Complaint__r.RecordType.DeveloperName, CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c,
                        CMPL123CME__Complaint__r.Service_Type__c
                        FROM CMPL123CME__EU_MIR__c 
                            WHERE Id IN :euMirIds]);
            }
            for (Regulatory_Task__c newTask : newRegTasks) {
                // Autoset Registration Number   WF Rule start
                CMPL123CME__MEDDEV__c relatedMDI = MDIs.get(newTask.MDI__c);
                CMPL123CME__EU_MIR__c relatedMIR = MIRs.get(newTask.EU_MIR__c);
                if (relatedMDI != null && relatedMDI.CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c != null) {
                    
                    String recordTypeName = relatedMDI.CMPL123CME__Complaint__r.RecordType.DeveloperName;
                    String CMSNextNumber = relatedMDI.CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c;
                    if (recordTypeName == 'Complaint' || recordTypeName == 'Inquiry') {
                        newTask.Registration_Number__c = CMSNextNumber + '(' + recordTypeName + ')';
                    } else if (recordTypeName == 'Service') {
                        newTask.Registration_Number__c = CMSNextNumber+ '(' + relatedMDI.CMPL123CME__Complaint__r.Service_Type__c
                                + ' ' + recordTypeName + ')';
                    }
                }
                if (relatedMIR != null && relatedMIR.CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c != null) {
                    String recordTypeNameMIR = relatedMIR.CMPL123CME__Complaint__r.RecordType.DeveloperName;
                    String CMSNextNumberMIR = relatedMIR.CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c;
                    if (recordTypeNameMIR == 'Complaint' || recordTypeNameMIR == 'Inquiry') {
                        newTask.Registration_Number__c = CMSNextNumberMIR+ '(' + recordTypeNameMIR + ')';
                    } else if (recordTypeNameMIR == 'Service') {
                        newTask.Registration_Number__c = CMSNextNumberMIR+ '(' + relatedMIR.CMPL123CME__Complaint__r.Service_Type__c
                                + ' ' + recordTypeNameMIR + ')';
                    }
                } 
                // Autoset Registration Number WF Rule end

                // Other Regulatory Opinion Tasks Workflow Update WF Rule start
                if (newTask.recordTypeId == competentAuthorityRegulatoryResponseRTID || newTask.recordTypeId == notifiedBodyRegulatoryResponseRTID) {
                    newTask.CMPL123Rule_Key_Value__c = 'REGULATORY_TASK_OTHER_WORKFLOW';
                } else {
                    newTask.CMPL123Rule_Key_Value__c = 'REGULATORY_TASK_WORKFLOW';
                }
                // Other Regulatory Opinion Tasks Workflow Update WF Rule end
            }
        }
    }
}