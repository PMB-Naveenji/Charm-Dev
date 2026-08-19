/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketFileTranslationController.
* @Why   : Class to Handle Different scenarios of Translation Task.
* @When  : 21-JAN-2019.
* @Where : From TicketFileTranslationController class, TicketFileTranslation page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    21-JAN-2019            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                        Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                        Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class TicketFileTranslationController {
    public List<ADDReviewFileTranslationController.attachmentInner> attachmentDetails { set; get; }
    public Boolean isSuccessful { set; get; }
    public Map<String, String> translatedAttMap { set; get; }

    String translationVendorEmail;

    public Boolean isMultipleVendorsSelected { get; set; }
    public Boolean isSentToVendor { get; set; }
    public Boolean isAssigned { get; set; }

    /*
    * @Method       : TicketFileTranslationController.
    * @Description  : Constructor.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public TicketFileTranslationController() {
        attachmentDetails = new List<ADDReviewFileTranslationController.attachmentInner>();
        isSuccessful = false;
        translatedAttMap = new Map<String, String>();

        String recordIds = ApexPages.currentPage().getParameters().get('ids');
        Set<String> setVendors = New Set<String>();

        isSentToVendor = false;
        isAssigned = false;
        isMultipleVendorsSelected = false;

        if (recordIds != null) {
            recordIds = recordIds.removeEnd(',');
            recordIds = recordIds.replaceAll('%2C',',');

            Set<String> ids = new Set<String>();
            ids.addAll(recordIds.split(','));

            for (Attachment__c att :[SELECT Id, Translation_Task__c, Translation_Task__r.Ticket_Number__c, Translation_Task__r.Vendor_Name__r.Vendor_Email__c,
                                            Translation_Task__r.CMPL123_WF_Status__c, Name, Division__c, Translation_Task__r.Vendor_Name__c,
                                            Ticket_Number__c, Related_Ticket_Id__c, (SELECT Id, Name, BodyLength FROM Attachments LIMIT 1)
                                        FROM Attachment__c
                                        WHERE Translation_Task__c IN :ids]) {
                if (att.Translation_Task__r.CMPL123_WF_Status__c != 'In Process' && att.Translation_Task__r.CMPL123_WF_Status__c != 'Opened'
                    && att.Translation_Task__r.CMPL123_WF_Status__c != 'Closed-Done') {
                    isSentToVendor = true;
                    break;
                }

                if (att.attachments.size() > 0) {
                    isAssigned = true;
                    Id parentRecordId = att.Translation_Task__c;
                    String status = att.Translation_Task__r.CMPL123_WF_Status__c;

                    //Added W-000054 - Show only sent attachments
                    Boolean boolIsSent = ((status != 'Opened' && status != 'In Process') ? true : false);

                    if (status == 'In Process' || boolIsSent) {
                        if (att.Translation_Task__r.Vendor_Name__r.Vendor_Email__c != null) {
                            translationVendorEmail = att.Translation_Task__r.Vendor_Name__r.Vendor_Email__c;
                        }

                        if (att.Translation_Task__r.Vendor_Name__c != null) {
                            setVendors.add(att.Translation_Task__r.Vendor_Name__c);
                        }

                        attachmentDetails.add(new ADDReviewFileTranslationController.attachmentInner(
                            att.Name,
                            att.Translation_Task__r.Ticket_Number__c,
                            att.Id,
                            att.attachments[0].Id,
                            att.attachments[0].BodyLength,
                            false,
                            att.Translation_Task__c,
                            att.attachments[0].Name,
                            parentRecordId,
                            'Translation Task'
                        ));
                    }

                    translatedAttMap.put(att.Id, '');
                }
            }
        } else {
            attachmentDetails = new List<ADDReviewFileTranslationController.attachmentInner>();
        }

        isMultipleVendorsSelected = (setVendors.size() > 1) ? true : false;
    }

    /*
    * @Method       : sendForTranslation.
    * @Description  : To send for translation.
    * @Invoke       : From ADDReviewFileTranslationController class, TicketFileTranslationController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void sendForTranslation() {
        Set<String> standardAttIds = new Set<String>();
        Map<String,Set<String>> mapTranslationTaskIds = new Map<String,Set<String>>();
        Map<String, ADDReviewFileTranslationController.attachmentInner> customAttWithDetails = new Map<String, ADDReviewFileTranslationController.attachmentInner>();

        for (ADDReviewFileTranslationController.attachmentInner attInner :attachmentDetails) {
            if (attInner.isSelected) {
                standardAttIds.add(attInner.standardAttachmentId);

                customAttWithDetails.put(attInner.customAttachmentId, attInner);

                if (!mapTranslationTaskIds.containsKey(attInner.translationTaskId)) {
                    mapTranslationTaskIds.put(attInner.translationTaskId, new Set<String>{attInner.customAttachmentId});
                } else {
                    mapTranslationTaskIds.get(attInner.translationTaskId).add(attInner.customAttachmentId);
                }
            }
        }

        if (standardAttIds.size() > 0) {
            String strCommentBody = 'Hello,<br/><br/> Translation Required </br></br><b> Task Comments </b>';

            for (Translation_Task__c objTranslationTask :[SELECT Id, Task_Comments__c
                                                            FROM Translation_Task__c
                                                            WHERE Task_Comments__c != null
                                                                AND Id IN: mapTranslationTaskIds.keySet()]) {
                strCommentBody += '</br>' + objTranslationTask.Task_Comments__c;
            }

            Map<Id, Attachment> attachmentMap = new Map<Id, Attachment>([SELECT Id, Name, ContentType, Body FROM Attachment WHERE ID IN :standardAttIds]);

            EmailServicesAddress emailAdd = [SELECT EmailDomainName, LocalPart FROM EmailServicesAddress WHERE LocalPart = 'translationservice' LIMIT 1];
            String serviceEmail = emailAdd.LocalPart + '@' + emailAdd.EmailDomainName;

            Translation_Log__c tLog = new Translation_Log__c(
                Attachment_Details_JSON__c = JSON.serializePretty(customAttWithDetails),
                Type__c = 'File',
                Translation_Task_Id__c = JSON.serializePretty(mapTranslationTaskIds.keySet())
            );

            insert tLog;

            strCommentBody += '<br/><br/>Thanks<br/>CHaRM';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            if (translationVendorEmail != null) {
                String[] toAddresses = new String[] {translationVendorEmail};
                mail.setToAddresses(toAddresses);
            }

            mail.setTargetObjectId(Userinfo.getUserId());

            mail.setCcAddresses(new String[] { serviceEmail });

            mail.setSubject('Translation Required(' + tLog.Id + ')');
            mail.setSaveAsActivity(false);
            //Added - W-000054
            mail.setSenderDisplayName('CHaRM');
            //Added - W-000054
            mail.setHtmlBody(strCommentBody);
            Messaging.EmailFileAttachment csvAttc;

            List<Messaging.EmailFileAttachment> attachFiles = new List<Messaging.EmailFileAttachment>();

            for (ADDReviewFileTranslationController.attachmentInner attInner :attachmentDetails) {
                if (attInner.isSelected) {
                    csvAttc = new Messaging.EmailFileAttachment();
                    csvAttc.setFileName(attInner.customAttachmentId + '-' + attachmentMap.get(attInner.standardAttachmentId).Name);
                    csvAttc.setContentType(attachmentMap.get(attInner.standardAttachmentId).ContentType);
                    csvAttc.setBody(attachmentMap.get(attInner.standardAttachmentId).Body);
                    attachFiles.add(csvAttc);
                }
            }

            mail.setFileAttachments(attachFiles);
            Messaging.sendEmail(new List<Messaging.Singleemailmessage>{mail});

            CMPL123__WF_Step__c wfStep = [SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name, CMPL123__Start_Status__r.Name
                                            FROM CMPL123__WF_Step__c
                                            WHERE CMPL123__Start_Status__r.Name = 'In Process'
                                                AND CMPL123__End_Status__r.Name = 'Task sent to vendor'
                                                AND CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Translation_Task'];

            List<CMPL123__WF_History__c> WFHistories = new list<CMPL123__WF_History__c>();
            List<Translation_Task__c> lstTranslationTasks = New List<Translation_Task__c>();

            for (String strKey :mapTranslationTaskIds.keySet()) {
                lstTranslationTasks.add(new Translation_Task__c(
                    CMPL123_WF_Status__c = wfStep.CMPL123__End_Status__r.Name,
                    CMPL123_WF_Action__c = wfStep.CMPL123__Action__r.Name,
                    CMPL123_WF_Action_Performed_On__c = DateTime.now(),
                    CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                    Email_Attachments__c = JSON.serializePretty(mapTranslationTaskIds.get(strKey)),
                    Id = strKey
                ));

                WFHistories.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(strKey, wfStep));
            }

            if (lstTranslationTasks.size() > 0) {
                update lstTranslationTasks;
            }

            if (WFHistories.size() > 0) {
                insert WFHistories;
            }

            isSuccessful = true;

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,Label.Translation_Task_File_Generation));
        } else {
            //Added W-000054 else message
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,Label.Translation_Task_Select_File_For_Translation));
            //Added W-000054 else message
        }
    }
}