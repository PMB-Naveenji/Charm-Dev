/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : TicketTranslationController.
 * @Why   : Class to handle different scenarios of Translation Task.
 * @When  : 23-MAR-2017.
 * @Where : From DownloadTranslationItems, TicketTranslation pages.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID                   Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                    23-MAR-2017            Work ID / Case ID                 Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    04-JUN-2020            Code Audit                        Removed 'System.debug()'.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    15-JUN-2020            Code Audit                        Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    09-JUL-2020            Code Audit                        Updated header comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    04-OCT-2020            Translation Issue                 Modified logic related to attachment's body
 *                                                 during Hypercare                  composition.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             30-JUN-2023            CHaRM R3.1, IPDR 116              Included the new "Is Voided" field to the query.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

public with sharing class TicketTranslationController {

    public List<Translation_Item__c> translationItems{set; get;}
    //Added - W-000173
    public List<Translation_Item__c> lstTranslationItemsToDownload{set; get;}
    public Boolean isMultipleVendorsSelected {get; set;}
    public Boolean isSentToVendor {get; set;}
    public Boolean isAssigned {get; set;}
    String translationVendorEmail;
    public long longFormat {get;set;}

    /*
    * @Method       : TicketTranslationController.
    * @Description  : It handles different scenarios of Translation Task.
    * @Invoke       : From TicketTranslationController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public TicketTranslationController() {
        translationItems = new List<Translation_Item__c>();
        lstTranslationItemsToDownload = new List<Translation_Item__c>();
        String recordIds = ApexPages.currentPage().getParameters().get('ids');
        Set<String> setVendors = New Set<String>();
        isSentToVendor = false;
        isAssigned = false;
        longFormat = System.now().getTime();
        isMultipleVendorsSelected = false;
        if(recordIds != null){
            recordIds = recordIds.removeEnd(',');
            recordIds = recordIds.replaceAll('%2C',',');
            Set<String> ids = new Set<String>();
            ids.addAll(recordIds.split(','));
            //Added - W-000142 - 10/09/2018 -- Translation_Task__r.Urgency__c
            //Added - W-000171 - 11/09/2018 -- Translation_Task__r.Task_Comments__c
            // R3.1, Larry: Added "Is Voided"
            for(Translation_Item__c objTranslationItem : [
                SELECT Id, Name, Field_Name__c, Native__c, Translated__c, Translation_Task__c, Is_Voided__c,
                Translation_Task__r.Urgency__c,Translation_Task__r.Task_Comments__c,Translation_Task__r.Vendor_Name__r.Name,
                Translation_Task__r.Name, Translation_Task__r.Country_Name__c,
                Translation_Task__r.CMPL123_WF_Status__c,Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c,
                Translation_Task__r.Vendor_Name__r.Vendor_Email__c,Translation_Task__r.Vendor_Name__c
                FROM Translation_Item__c
                WHERE Translation_Task__c IN :ids
                AND Translation_Task__r.RecordType.Name = 'Text Translation'
                ORDER BY Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c
            ]) {
                if(objTranslationItem.Translation_Task__r.CMPL123_WF_Status__c != 'In Process' &&
                    objTranslationItem.Translation_Task__r.CMPL123_WF_Status__c != 'Opened' &&
                    objTranslationItem.Translation_Task__r.CMPL123_WF_Status__c != 'Closed-Done'
                ){
                    isSentToVendor = true;
                } else if(objTranslationItem.Translation_Task__r.CMPL123_WF_Status__c == 'In Process'){
                    isAssigned = true;
                    if (objTranslationItem.Translation_Task__r.Vendor_Name__r.Vendor_Email__c != null) {
                        translationVendorEmail = objTranslationItem.Translation_Task__r.Vendor_Name__r.Vendor_Email__c;
                    }
                    if(objTranslationItem.Translation_Task__r.Vendor_Name__c != null){
                        setVendors.add(objTranslationItem.Translation_Task__r.Vendor_Name__c);
                    }
                    //if (objTranslationItem.Translated__c == null) {
                    translationItems.add(objTranslationItem);
                    //}
                }
                //Added - W-000173
                lstTranslationItemsToDownload.add(objTranslationItem);
            }
        } else {
            translationItems = new List<Translation_Item__c>();
        }

        isMultipleVendorsSelected = setVendors.size() > 1;
    }

    /*
    * @Method       : save.
    * @Description  : To save records.
    * @Invoke       : From DownloadTranslationItems, TicketTranslation pages.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void save(){

        EmailServicesAddress emailAdd = [SELECT EmailDomainName, LocalPart FROM EmailServicesAddress WHERE LocalPart = 'translationservice' LIMIT 1];
        String serviceEmail = emailAdd.LocalPart + '@' + emailAdd.EmailDomainName;

        try{
            List<SObject> updatableTasks = new list<SObject>();
            List<CMPL123__WF_History__c> WFHistories = new list<CMPL123__WF_History__c>();
            String delimeter = ',';
            String csvHeader = '"Field Name"' + delimeter
                               + '"Ticket Number"' + delimeter
                               + '"Native"' + delimeter
                               + '"Translated"' + delimeter
                               + '"Related Id"' + delimeter
                               + '"Urgency"' + delimeter
                               + '"Country"\n';
            String csvBody = '';
            Set<String> relatedTaskIds = new Set<String>();
            //Added - W-000172 - 25/10/2018
            Set<String> relatedDeselectedTaskIds = new Set<String>();
            //Added - W-000171 - 11/09/2018
            String strCommentBody = 'Hello,<br/><br/> Translation Required </br></br><b> Task Comments </b>';
            //Added - W-000171 - 11/09/2018

            //Added - W-000172 - 25/10/2018
            String strMessage = Label.Translation_Task_File_Generation;
            String strStatus = 'Task sent to vendor';

            for(Translation_Item__c task : translationItems){
                if(task.Translated__c == null){
                    //Added - W-000171 - 11/09/2018
                    if(task.Translation_Task__r.Task_Comments__c != null && !relatedTaskIds.contains(task.Translation_Task__c)){
                        strCommentBody += '</br>' + task.Translation_Task__r.Task_Comments__c;
                    }
                    //Added - W-000172 - 25/10/2018
                    relatedDeselectedTaskIds.remove(task.Translation_Task__c);
                    //Added - W-000171 - 11/09/2018
                    relatedTaskIds.add(task.Translation_Task__c);
                    //Translation defect fix BEGIN
                    csvBody += '"' + task.Field_Name__c + '"' + delimeter 
                                   + '"' + task.Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c + '"' + delimeter;
                    if (task.Native__c != null) {
                        csvBody += task.Native__c.escapeCsv() + delimeter;
                    } else {
                        csvBody += '""' + delimeter;
                    }
                    if (task.Translated__c != null) {
                        csvBody += task.Translated__c.escapeCsv() + delimeter;
                    } else {
                        csvBody += '""' + delimeter;
                    }
                    csvBody += '"' + task.Id + '"' + delimeter 
                            + '"' + task.Translation_Task__r.Urgency__c + '"' + delimeter 
                            + '"' + task.Translation_Task__r.Country_Name__c + '"' + '\n';
                    //Translation defect fix END
                }else{
                    updatableTasks.add(new Translation_Item__c(Id = task.Id, Translated__c = task.Translated__c));
                    if(!relatedTaskIds.contains(task.Translation_Task__c)){
                        relatedDeselectedTaskIds.add(task.Translation_Task__c);
                    }
                }
            }
            //Added - W-000172 - 25/10/2018
            if(relatedTaskIds.size() > 0 ){
                String fileBody = csvHeader + csvBody;

                Translation_Log__c tLog = new Translation_Log__c(Translation_Task_Id__c = JSON.serializePretty(relatedTaskIds));
                insert tLog;
                strCommentBody += '<br/><br/>Thanks<br/>CHaRM';
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                if (translationVendorEmail != null) {
                    String[] toAddresses = new String[] {translationVendorEmail};
                        mail.setToAddresses(toAddresses);
                }
                mail.setTargetObjectId(Userinfo.getUserId());
                mail.setCcAddresses(new String[] {serviceEmail});

                mail.setSubject('Translation Required('+tLog.Id+')');
                mail.setSaveAsActivity(false);
                //Added - W-000171 - 11/09/2018
                mail.setHtmlBody(strCommentBody);
                //Added - W-000171 - 11/09/2018

                // Added - W-000172
                mail.setSenderDisplayName('CHaRM');
                // Added - W-000172
                Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();

                longFormat = System.now().getTime();
                csvAttc.setFileName(longFormat+'Translation.csv');

                csvAttc.setBody(Blob.valueOf('\uFEFF'+fileBody));
                csvAttc.setContentType('text/csv; charset=UTF-8');
                mail.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
                Messaging.sendEmail(new List<Messaging.Singleemailmessage>{mail});


                CMPL123__WF_Step__c wfStepTasksenttovendor = [SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,
                                              CMPL123__Start_Status__r.Name FROM CMPL123__WF_Step__c Where
                                              CMPL123__Start_Status__r.Name = 'In Process' AND CMPL123__End_Status__r.Name =: strStatus AND
                                              CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Translation_Task' LIMIT 1];



                for(String taskId : relatedTaskIds) {
                    WFHistories.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(taskId, wfStepTasksenttovendor));
                    updatableTasks.add(
                        new Translation_Task__c (
                            CMPL123_WF_Status__c = wfStepTasksenttovendor.CMPL123__End_Status__r.Name,
                            CMPL123_WF_Action__c = wfStepTasksenttovendor.CMPL123__Action__r.Name,
                            CMPL123_WF_Action_Performed_On__c = DateTime.now(),
                            CMPL123_WF_Action_Performed_By__c = Userinfo.getUserId(),
                            Id = taskId
                        )
                    );
                }
            }

            //Added - W-000172 - 25/10/2018
            if(relatedDeselectedTaskIds.size() > 0 ){
                if(relatedTaskIds.size() == 0){
                    strMessage = Label.Translation_Task_Nothing_to_Translate;
                }
                strStatus = 'Closed-Voided';
                CMPL123__WF_Step__c wfStepClosed = [SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,
                                                    CMPL123__Start_Status__r.Name FROM CMPL123__WF_Step__c Where
                                                    CMPL123__Start_Status__r.Name = 'In Process' AND CMPL123__End_Status__r.Name =: strStatus AND
                                                    CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Translation_Task' LIMIT 1];

                for(String taskId : relatedDeselectedTaskIds) {
                    WFHistories.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(taskId, wfStepClosed));
                    updatableTasks.add(
                        new Translation_Task__c (
                            CMPL123_WF_Status__c = wfStepClosed.CMPL123__End_Status__r.Name,
                            CMPL123_WF_Action__c = wfStepClosed.CMPL123__Action__r.Name,
                            CMPL123_WF_Action_Performed_On__c = DateTime.now(),
                            CMPL123_WF_Action_Performed_By__c = Userinfo.getUserId(),
                            Id = taskId
                        )
                    );
                }
            }
            //Added - W-000172 - 25/10/2018

            if(updatableTasks.size() > 0){
                update updatableTasks;
            }
            if(WFHistories.size() > 0){
                insert WFHistories;
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,strMessage));
        }catch(Exception exp){
            Apexpages.addMessages(exp);
        }
    }

    /*
    * @Method       : downloadTranslationExcel.
    * @Invoke       : From DownloadTranslationItems, TicketTranslation pages.
    * @Description  : To download translation excel.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    public PageReference downloadTranslationExcel() {
        PageReference objPageReference = Page.DownloadTranslationItems;
        objPageReference.setRedirect(false);
        return objPageReference;
    }
}