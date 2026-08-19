/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDReviewFileTranslationController.
* @Why   : Handles all the customization involved on ADDReviewFileTranslation page.
* @When  : 23-MAR-2017.
* @Where : From ADDReviewFileTranslation page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID            Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				   23-MAR-2017			  Work ID / Case ID          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                 Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                 Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                    11-AUG-2020            Code Audit                 Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDReviewFileTranslationController {

    public List<attachmentInner> attachmentDetails {set; get;}
    public Boolean isSuccessful {set; get;}
    public String status {set; get;}
    public Map<String, String> translatedAttMap {set;get;}

    String translationVendorEmail;

    ApexPages.StandardController standardController;
    String currentRecordId;
    String currentRecordComment;

    /*
    * @Method       : Constructor.
    * @Description  : To initialize the class variables.
    * @Invoke       : From ADDReviewFileTranslation page.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController standardController.
    */
    public ADDReviewFileTranslationController(ApexPages.StandardController standardController) {
        isSuccessful = false;
        this.standardController = standardController;
        attachmentDetails = new List<attachmentInner>();
        translatedAttMap = new Map<String, String>();
        if(!Test.isRunningTest()) {
            this.standardController.addFields(new List<String> {
                'Parent_Ticket__c', 'Id', 'CMPL123_WF_Status__c', 'Vendor_Name__r.Vendor_Email__c', 'Task_Comments__c', 'Email_Attachments__c'
            });
        }
        Translation_Task__c currentRecord = (Translation_Task__c)standardController.getRecord();
        translationVendorEmail = currentRecord.Vendor_Name__r.Vendor_Email__c;
        currentRecordId = currentRecord.Id;
        currentRecordComment = currentRecord.Task_Comments__c;
        status = currentRecord.CMPL123_WF_Status__c;
        if (currentRecord != null){
            //Commented W-000054 - display list for all status
            //&& (status == 'Opened' || status == 'In Process' || status == 'Translation Pending Review')) {

            for (Attachment__c att : [SELECT Id, Translation_Task__c, Name, Division__c, Ticket_Number__c, Related_Ticket_Id__c,
                                      (SELECT Id, Name, BodyLength FROM Attachments LIMIT 1) FROM Attachment__c
                                      WHERE Translation_Task__c =: currentRecordId]) {
                if (att.attachments.size() > 0) {
                    Id parentRecordId = att.Translation_Task__c;
                    //Added W-000054 - Show only sent attachments
                    Boolean boolIsSent = ((status != 'Opened' && status != 'In Process' && currentRecord.Email_Attachments__c != '' && String.valueOf(currentRecord.Email_Attachments__c).contains(att.Id)) ? true : false);
                    if(status == 'Opened' || status == 'In Process' || boolIsSent){
                        attachmentDetails.add (
                            new attachmentInner(att.Name, att.Ticket_Number__c, att.Id,
                                                att.attachments[0].Id, att.attachments[0].BodyLength,
                                                false, att.Translation_Task__c,
                                                att.attachments[0].Name, currentRecord.Id, 'Translation Task'
                                               )
                        );
                    }
                    translatedAttMap.put(att.Id,'');
                }
            }

            if (status == 'Translation Pending Review' || status == 'Task sent to vendor' ) {
                for (Translation_Task__c tt : [SELECT Id, (SELECT Id, Name FROM Attachments ORDER BY CreatedDate ASC) FROM Translation_Task__c WHERE Id=:currentRecordId]) {
                    for(Attachment att : tt.Attachments) {
                        if (att.Name.contains('-')) {
                            translatedAttMap.put(att.Name.substringBefore('-'), att.Id);
                        }
                    }
                }
            }
        }
    }

    /*
    * @Method       : sendForTranslation.
    * @Description  : To send attachment for translation.
    * @Invoke       : from ADDReviewFileTranslation page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void sendForTranslation() {
        Set<String> standardAttIds = new Set<String>();
        Map<String, attachmentInner> customAttWithDetails = new Map<String, attachmentInner>();
        for (attachmentInner attInner : attachmentDetails) {
            if (attInner.isSelected) {
                standardAttIds.add(attInner.standardAttachmentId);
                customAttWithDetails.put(attInner.customAttachmentId, attInner);
            }
        }

        if (standardAttIds.size() > 0) {
            Map<Id, Attachment> attachmentMap = new Map<Id, Attachment>([SELECT Id, Name, ContentType, Body FROM Attachment WHERE ID IN: standardAttIds]);


            EmailServicesAddress emailAdd = [SELECT EmailDomainName, LocalPart FROM EmailServicesAddress WHERE LocalPart = 'translationservice' LIMIT 1];
            String serviceEmail = emailAdd.LocalPart + '@' + emailAdd.EmailDomainName;

            Translation_Log__c tLog = new Translation_Log__c
                (
                    Attachment_Details_JSON__c = JSON.serializePretty(customAttWithDetails),
                    Type__c = 'File', Translation_Task_Id__c = JSON.serializePretty(new Set<String>{currentRecordId}),
                    Translation_Id__c = currentRecordId
                );
            insert tLog;

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            if (translationVendorEmail != null) {
                String[] toAddresses = new String[] {translationVendorEmail};
                mail.setToAddresses(toAddresses);
            }
            mail.setTargetObjectId(Userinfo.getUserId());

            mail.setCcAddresses(new String[] {serviceEmail});

            mail.setSubject('Translation Required(' + tLog.Id + ')');
            mail.setSaveAsActivity(false);
            //Added - W-000054
            mail.setSenderDisplayName('CHaRM');
            String strCommentBody = 'Hello,<br/><br/> Translation Required </br></br><b> Task Comments </b> </br>' + (currentRecordComment != null ? currentRecordComment : '') + '<br/><br/>Thanks<br/>CHaRM';
            //Added - W-000054
            mail.setHtmlBody(strCommentBody);
            Messaging.EmailFileAttachment csvAttc;

            List<Messaging.EmailFileAttachment> attachFiles = new List<Messaging.EmailFileAttachment>();
            for (attachmentInner attInner : attachmentDetails) {
                if (attInner.isSelected) {
                    csvAttc = new Messaging.EmailFileAttachment();
                    csvAttc.setFileName(attInner.customAttachmentId + '-' + attachmentMap.get(attInner.standardAttachmentId).Name);
                    csvAttc.setContentType(attachmentMap.get(attInner.standardAttachmentId).ContentType);
                    csvAttc.setBody(attachmentMap.get(attInner.standardAttachmentId).Body);
                    attachFiles.add(csvAttc);
                }
            }
            mail.setFileAttachments(attachFiles);
            //if(!Test.isRunningTest()) {
                Messaging.sendEmail(new List<Messaging.Singleemailmessage>{mail});

                CMPL123__WF_Step__c wfStep = [SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,
                    CMPL123__Start_Status__r.Name FROM CMPL123__WF_Step__c Where
                    CMPL123__Start_Status__r.Name = 'In Process' AND CMPL123__End_Status__r.Name = 'Task sent to vendor' AND
                    CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Translation_Task'];

                List<CMPL123__WF_History__c> WFHistories = new list<CMPL123__WF_History__c>();

                update new Translation_Task__c(
                    CMPL123_WF_Status__c = wfStep.CMPL123__End_Status__r.Name,
                    CMPL123_WF_Action__c = wfStep.CMPL123__Action__r.Name,
                    CMPL123_WF_Action_Performed_On__c = DateTime.now(),
                    CMPL123_WF_Action_Performed_By__c = Userinfo.getUserId(),
                    Email_Attachments__c = JSON.serializePretty(customAttWithDetails.keySet()),
                    Id = currentRecordId
                );
                insert ComplaintTriggerHandler.processAutomatedHistoryRecord(currentRecordId, wfStep);

                isSuccessful = true;
                ApexPages.addMessage(new ApexPages.Message(
                        ApexPages.Severity.CONFIRM,Label.Translation_Task_File_Generation
                    )
                );
        } else {
            //Added W-000054 else message
            ApexPages.addMessage(new ApexPages.Message( ApexPages.Severity.Warning,Label.Translation_Task_Select_File_For_Translation));
            //Added W-000054 else message
        }
    }

    /*
    * @Method       : reviewTranslation.
    * @Description  : To review translation.
    * @Invoke       : from ADDReviewFileTranslation page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
     public void reviewTranslation() {
        Set<String> standardAttIds = new Set<String>();
        Map<String, attachmentInner> customAttWithDetails = new Map<String, attachmentInner>();
        for (attachmentInner attInner : attachmentDetails) {
            if (attInner.isSelected) {
                standardAttIds.add(attInner.standardAttachmentId);
                customAttWithDetails.put(attInner.customAttachmentId, attInner);
            }
        }

        if (standardAttIds.size() > 0) {

                CMPL123__WF_Step__c wfStep = [SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,
                    CMPL123__Start_Status__r.Name FROM CMPL123__WF_Step__c Where
                    CMPL123__Start_Status__r.Name = 'Translation Pending Review' AND CMPL123__End_Status__r.Name = 'Closed-Done' AND
                    CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Translation_Task' LIMIT 1];

                List<CMPL123__WF_History__c> WFHistories = new list<CMPL123__WF_History__c>();

                update new Translation_Task__c(
                    CMPL123_WF_Status__c = wfStep.CMPL123__End_Status__r.Name,
                    CMPL123_WF_Action__c = wfStep.CMPL123__Action__r.Name,
                    CMPL123_WF_Action_Performed_On__c = DateTime.now(),
                    CMPL123_WF_Action_Performed_By__c = Userinfo.getUserId(),
                    Email_Attachments__c = JSON.serializePretty(customAttWithDetails.keySet()),
                    Id = currentRecordId
                );
                insert ComplaintTriggerHandler.processAutomatedHistoryRecord(currentRecordId, wfStep);

                isSuccessful = true;
                ApexPages.addMessage(new ApexPages.Message(
                        ApexPages.Severity.CONFIRM,Label.Translation_Task_File_Population
                    )
                );
        } else {
            //Added W-000054 else message
            ApexPages.addMessage(new ApexPages.Message( ApexPages.Severity.Warning,Label.Translation_Task_Select_File_For_Translation));
            //Added W-000054 else message
        }
    }

    /* attachment details */
    public class attachmentInner {

        public String fileName {set;get;}
        public String ticketNumber {set;get;}
        public String customAttachmentId {set;get;}
        public String standardAttachmentId {set;get;}
        public Decimal fileSize {set;get;}
        public Boolean isSelected {set;get;}
        public String relatedParentId {set;get;}
        public String standardAttName {set;get;}
        public String translationTaskId {set;get;}
        public String objectLabel {set; get;}

        public attachmentInner(String fileName, String ticketNumber, String customAttachmentId,
            String standardAttachmentId, decimal fileSize, Boolean isSelected, String relatedParentId,
            String standardAttName, String translationTaskId, String objectLabel) {

            this.fileName = fileName;
            this.ticketNumber = ticketNumber;
            this.customAttachmentId = customAttachmentId;
            this.standardAttachmentId = standardAttachmentId;
            this.fileSize = fileSize;
            this.isSelected = isSelected;
            this.relatedParentId = relatedParentId;
            this.standardAttName = standardAttName;
            this.translationTaskId = translationTaskId;
            this.objectLabel = objectLabel;
        }
    }
}