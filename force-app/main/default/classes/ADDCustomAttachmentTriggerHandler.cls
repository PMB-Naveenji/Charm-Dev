/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : ADDCustomAttachmentTriggerHandler.
 * @Why   : Handles all the customization involved on custom attachment object.
 * @When  : 23-MAR-2017.
 * @Where : From Attachment_AuditTrigger trigger.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID               Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                    23-MAR-2017            Work ID / Case ID             Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    04-JUN-2020            Code Audit                    Removed 'System.debug()'.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    15-JUN-2020            Code Audit                    Removed commented code. Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    22-JUN-2020            #146/CHARM-2791               Removed parent ticket last modified date updating
 *                                                                                   (TicketUpdateUtility.updateParentOnChildUpdate method
 *                                                                                   call in afterInsert() and afterUpdate() methods).
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    23-JUN-2020            #123.1/CHARM-2878             Added update of parent Customer Response.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    28-DEC-2020            TWD Upgrade issue             Added 'executeLogicFromWFRules()' method to move logic
 *                                                                                   from Workflow Rules with Field Updates
 *                                                                                   on Attachment to Apex.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Orlando Briceno Capgemini 10-FEB-2021           CHaRM 141                     MDC Creation Fix
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             31-JAN-2023            CHaRM R3.0, IPDR 411          An inserted Attachment's "Registration Attachment" field
 *                                                                               now checks that there is at least one active related
 *                                                                               Ticket Search before making an MDC
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dinesh Kumar             29-NOV-2023            CHaRM R4/BTSIT10110          Commented the Method "updateCustomerResponse", Since the 
 *                                                                              Last Modified Date and Time field will be updated only on
 *                                                                              Assignee Name is Changed and Status is Closed-Done.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * CHaRM COE                03-JUN-2026            CHaRM R9.0/IPDR-165  	    Updated createMDCTicket() method to generate an MDC ticket  
 * 																				for the Quality Non-Complaint group only when a Customer
 *                                                                              Response child record exists for the Inquiry ticket.                                                                     												  			       																          																		                                                                     
 * --------------------------------------------------------------------------------------------------------------------------------------
 *  CHaRM COE                29-JUN-2026             CHaRM R9.0/IPDR 409        Added configurable MDC prevention validation to generate MDC 
 * 																				records only for eligible Attachment based on the parent 
 * 																				Ticket creation time and configured prevention interval.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

public class ADDCustomAttachmentTriggerHandler extends TriggerHandler {
    public static Boolean executeAttachmentFlag = true;
    private static Boolean executeAttachmentValidationOnceFlag = false;

    /*
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeInsert() {
        preventCreatingDeletingIfParentIsSpecific((List<Attachment__c>) Trigger.new);
        preventTranslationAttachmentUpsertClosed((List<Attachment__c>) Trigger.new);
        updateTicketData((List<Attachment__c>) Trigger.new);

        // TWD Upgrade issue - FIX START
        executeLogicFromWFRules();
        // TWD Upgrade issue - FIX END

        // #123.1/CHARM-2878: Last Modified Date/Time updating
        updateLastModifiedDateTime();
    }

    public void updateTicketData(List<Attachment__c> attachmentList) {
        List<Id> meddevIdList = new List<Id>();
        List<Id> euMirIdList = new List<Id>();
        List<Id> regulatoryTaskIdList = new List<Id>();
        List<Id> translationTaskIdList = new List<Id>();
        List<Id> customerResponseIdList = new List<Id>();

        for (Attachment__c attachment : attachmentList) {
            if (attachment.MEDDEV__c != null && attachment.Ticket__c == null) {
                meddevIdList.add(attachment.MEDDEV__c);
            }

            if (attachment.EU_MIR__c != null && attachment.Ticket__c == null) {
                eumirIdList.add(attachment.EU_MIR__c);
            }

            if (attachment.Regulatory_Task__c != null && attachment.Ticket__c == null) {
                regulatoryTaskIdList.add(attachment.Regulatory_Task__c);
            }

            if (attachment.Translation_Task__c != null && attachment.Ticket__c == null) {
                translationTaskIdList.add(attachment.Translation_Task__c);
            }

            if (attachment.Customer_Response__c != null && attachment.Ticket__c == null) {
                customerResponseIdList.add(attachment.Customer_Response__c);
            }
        }

        Map<Id, CMPL123CME__MEDDEV__c> meddevMap;
        if (meddevIdList.size() > 0) {
            meddevMap = new Map<Id, CMPL123CME__MEDDEV__c>([
                SELECT Id, CMPL123CME__Complaint__c
                FROM CMPL123CME__MEDDEV__c
                WHERE Id IN :meddevIdList]);
        }

        Map<Id, CMPL123CME__EU_MIR__c> eumirMap;
        if (eumirIdList.size() > 0) {
            eumirMap = new Map<Id, CMPL123CME__EU_MIR__c>([
                SELECT Id, CMPL123CME__Complaint__c
                FROM CMPL123CME__EU_MIR__c
                WHERE Id IN :eumirIdList]);
        }

        Map<Id, Regulatory_Task__c> regulatoryTaskMap;
        if (regulatoryTaskIdList.size() > 0) {
            //Defect Fix - Varsha Hariharan
            regulatoryTaskMap = new Map<Id, Regulatory_Task__c> ([
                SELECT Id, MDI__r.CMPL123CME__Complaint__c, EU_MIR__r.CMPL123CME__Complaint__c
                FROM Regulatory_Task__c
                WHERE Id IN :regulatoryTaskIdList]);
        }

        Map<Id, Translation_Task__c> translationTaskMap;
        if (translationTaskIdList.size() > 0) {
            translationTaskMap = new Map<Id, Translation_Task__c>([
                SELECT Id, Parent_Ticket__c
                FROM Translation_Task__c
                WHERE Id IN :translationTaskIdList]);
        }

        Map<Id, Customer_Response__c> customerResponseMap;
        if(customerResponseIdList.size() > 0){
            customerResponseMap = new Map<Id, Customer_Response__c>([
                SELECT Id, Event__c
                FROM Customer_Response__c
                WHERE Id IN :customerResponseIdList]);
        }

        for (Attachment__c attachment : attachmentList) {
            if (attachment.MEDDEV__c != null && attachment.Ticket__c == null) {
                if (meddevMap.size() > 0 && meddevMap.containsKey(attachment.MEDDEV__c)) {
                    attachment.Ticket__c = meddevMap.get(attachment.MEDDEV__c).CMPL123CME__Complaint__c;
                }
            }

            if (attachment.EU_MIR__c != null && attachment.Ticket__c == null) {
                if (eumirMap.size() > 0 && eumirMap.containsKey(attachment.EU_MIR__c)) {
                    attachment.Ticket__c = eumirMap.get(attachment.EU_MIR__c).CMPL123CME__Complaint__c;
                }
            }

            if (attachment.Regulatory_Task__c != null && attachment.Ticket__c == null) {
                if (regulatoryTaskMap.size() > 0 && regulatoryTaskMap.containsKey(attachment.Regulatory_Task__c)) {
                    //Defect Fix - Varsha Hariharan
                    if(regulatoryTaskMap.get(attachment.Regulatory_Task__c).MDI__r.CMPL123CME__Complaint__c != NULL){
                        attachment.Ticket__c = regulatoryTaskMap.get(attachment.Regulatory_Task__c).MDI__r.CMPL123CME__Complaint__c;
                    }
                    else{
                        attachment.Ticket__c = regulatoryTaskMap.get(attachment.Regulatory_Task__c).EU_MIR__r.CMPL123CME__Complaint__c;
                    }
                    //End of Changes - Defect Fix - Varsha Hariharan
                }
            }

            if (attachment.Translation_Task__c != null && attachment.Ticket__c == null) {
                if (translationTaskMap.size() > 0 && translationTaskMap.containsKey (attachment.Translation_Task__c)) {
                    attachment.Ticket__c = translationTaskMap.get(attachment.Translation_Task__c).Parent_Ticket__c;
                }
            }

            if (attachment.Customer_Response__c != null && attachment.Ticket__c == null) {
                if (customerResponseMap.size() > 0 && customerResponseMap.containsKey(attachment.Customer_Response__c)) {
                    attachment.Ticket__c = customerResponseMap.get(attachment.Customer_Response__c).Event__c;
                }
            }

            //19APR19 - #673 - if parent in Appending Regulatory Correspondence status and integration user, attachment type default to Regulatory Correspondence
            if (String.isNotBlank(attachment.Parent_Id__c)
                    && attachment.Parent_Id__c.containsIgnoreCase('Appending Regulatory Correspondence')
                    && UserInfo.getProfileId() == System.Label.Integration_Profile_ID) {
                attachment.Attachment_Type__c = 'Regulatory Correspondence';
            }

            attachment.Attachment_Type_And_Status__c = attachment.Attachment_Type__c + ',' + attachment.Attachment_Status__c;
        }
    }

    /*
    * @Method       : afterInsert
    * @Invoke       : Events from TriggerHandler after insert
    * @Description  : To handle all the logic in after insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterInsert() {
        CMPL123.AuditHandler.handleAudit();
        validateAttachmentAvailability((List<Attachment__c>) Trigger.new);
        // Def #146/CHARM-2791: update parent Customer Response
        // CHaRM-R4: Commented the below code since the method "updateCustomerResponse" is commented.
        // Moved the Logic to Flows "Update Last Modified Date And Time Field".
      /*  if (UserInfo.getProfileId() != System.Label.Integration_Profile_ID) {
            updateCustomerResponse((List<Attachment__c>) Trigger.new);
        }*/

        // #141 CHaRM Call to new MDC create logic
        Map<Id, Attachment__c> attachmentMap = new Map<Id, Attachment__c>((List<Attachment__c>)Trigger.new);
        ADD_App_Settings__c addApp = ADD_App_Settings__c.getInstance();
        /*CHaRM R9.0/IPDR-409 : Fallback switch to immediately use the existing MDC generation logic.
        This feature was introduced as a safeguard in case high-volume attachment
        loads from CMSNext cause issues with the new MDC prevention logic.*/
        if (addApp != null && addApp.Enable_MDC_Prevention_Logic__c) {
            createMDCTicket(attachmentMap);
            return;
        }
        
        Set<Id> ticketIds = new Set<Id>();
        for (Attachment__c att : (List<Attachment__c>) Trigger.new) {
            if (att.Ticket__c != null) {
                ticketIds.add(att.Ticket__c);
            }
        }
        
        if (!ticketIds.isEmpty()) {
            Map<Id, CMPL123CME__Complaint__c> ticketMap =
                new Map<Id, CMPL123CME__Complaint__c>(
                    [SELECT Id, CreatedDate FROM CMPL123CME__Complaint__c WHERE Id IN :ticketIds] );
            Map<Id,Attachment__c> filteredAttachmentMap = new Map<Id,Attachment__c>();
            for (Attachment__c attachmentRecord : (List<Attachment__c>)Trigger.new) {
                CMPL123CME__Complaint__c ticket = ticketMap.get(attachmentRecord.Ticket__c);
                Integer minutesToAdd = Integer.valueOf(addApp.MDC_Generation_Prevention_Minutes__c);
                /*CHaRM R9.0/IPDR-409 : Prevent MDC generation for Attachments added shortly after ticket creation.
                 MDC will only be generated once the configured prevention window has elapsed.
                 This avoids creating MDCs for newly created tickets. After the configured
                 time threshold is reached, MDC generation resumes as normal.*/
                if (System.now() > ticket.CreatedDate.addMinutes(minutesToAdd)) {
                    filteredAttachmentMap.put(attachmentRecord.Id, attachmentRecord);
                }
            }
            if(!filteredAttachmentMap.isEmpty()){
                createMDCTicket(filteredAttachmentMap);
            }
        }
    }
    
    

    /*
    * @Method       : beforeUpdate
    * @Invoke       : Events from TriggerHandler before update
    * @Description  : To handle all the logic in before update event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeUpdate() {
        List<Attachment__c> newAttachments = (List<Attachment__c>) Trigger.new;

        preventTranslationAttachmentUpsertClosed(newAttachments);

        if (!executeAttachmentValidationOnceFlag) {
            executeAttachmentValidationOnceFlag = true;
            validateAttachmentAvailability((List<Attachment__c>) Trigger.new);
        }

        for (Attachment__c attachment : newAttachments) {
            attachment.Attachment_Type_And_Status__c = attachment.Attachment_Type__c
                    + ',' + attachment.Attachment_Status__c;
        }

        // TWD Upgrade issue - FIX START
        executeLogicFromWFRules();
        // TWD Upgrade issue - FIX END

        // #123.1/CHARM-2878: Last Modified Date/Time updating
        updateLastModifiedDateTime();

        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterUpdate
    * @Invoke       : Events from TriggerHandler after update
    * @Description  : To handle all the logic in after update event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterUpdate() {
        CMPL123.AuditHandler.handleAudit();

        List<Attachment__c> newAttachments = (List<Attachment__c>) Trigger.new;

        if (ADDCustomAttachmentTriggerHandler.executeAttachmentFlag) {
            ADDCustomAttachmentTriggerHandler.executeAttachmentFlag = false;
            Set<Id> deleteAttachmentIdSet = new Set<Id>();

            Map<Id,Attachment__c> attachmentIdAndDetailsMap = (Map<Id,Attachment__c>)Trigger.newMap;

            Map<Id,String> CustomAtchIdAndNameMap = new Map<Id,String>();
            for (Attachment atch: [
                SELECT ParentId, Name FROM Attachment
                WHERE ParentId IN :attachmentIdAndDetailsMap.keySet()]) 
            {
                CustomAtchIdAndNameMap.put(atch.ParentId,atch.Name); //Added - 09MAY2019 - #747 CMSNext file not having extension
            }


            for (Attachment__c objAttachment : newAttachments) {
                if (!CustomAtchIdAndNameMap.isEmpty() && objAttachment.Customer_Response__c != null) {
                    if (CustomAtchIdAndNameMap.get(objAttachment.Id) == objAttachment.Name) {
                        if (objAttachment.Send_to_CMSNext__c && String.isNotBlank(objAttachment.File_Name__c)) {
                            if (!String.isBlank(objAttachment.UNC_Path__c)) {
                                deleteAttachmentIdSet.add(objAttachment.Id);
                            }
                        }
                    } else {
                        objAttachment.addError(System.Label.Attachment_Name_and_File_Name_error);
                    }
                }
            }

            if (deleteAttachmentIdSet.size() > 0) {
                delete [SELECT Id FROM Attachment WHERE ParentId IN : deleteAttachmentIdSet];
            }
        }
        // Def #146/CHARM-2791: update parent Customer Response
        // CHaRM-R4: Commented the below code since the method "updateCustomerResponse" is commented.
        // Moved the Logic to Flows "Update Last Modified Date And Time Field".
      /*  if (UserInfo.getProfileId() != System.Label.Integration_Profile_ID) {
            updateCustomerResponse((List<Attachment__c>) Trigger.new);
        }*///CHaRM-R4
    }

    /*
    * @Method       : beforeDelete
    * @Invoke       : Events from TriggerHandler before delete
    * @Description  : To handle all the logic in before delete event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeDelete() {
        Map<Id, String> parentIdWithObjectMap = new Map<Id, String>();

        preventCreatingDeletingIfParentIsSpecific((List<Attachment__c>) Trigger.old);
        preventTranslationAttachmentUpsertClosed((List<Attachment__c>)Trigger.old);

        for (Attachment__c att : (List<Attachment__c>)Trigger.old) {
            if (att.Customer_Response__c != null && !att.Is_Delete__c) {
                att.addError('This Attachment is already processed and send to CMSNeXT. User should not delete this');
            }
            String parentId = (String.isNotBlank(att.Parent_Id__c) ? att.Parent_Id__c : '')
                    + '' + (String.isNotBlank(att.Related_Parent_Id__c) ? att.Related_Parent_Id__c : '');

            if (String.isNotBlank(parentId) && parentId.contains('-')) {
                String ticketKeyPefix = CMPL123CME__Complaint__c.SObjectType.getDescribe().getKeyPrefix();
                List<String> parentIDList = new List<String>(parentId.trim().split(' &&'));
                Id recordId;
                String objectAPI;
                if (parentIDList.size() == 1) {
                    recordId = Id.valueOf(parentId.substringBefore('-').trim());
                    objectAPI = recordId.getSobjectType().getDescribe().getName();
                    parentIdWithObjectMap.put(recordId, objectAPI);
                } else if (parentIDList.size() > 1) {
                    for (String recId : parentIDList) {
                        if (recId.trim().substring(0,3) != ticketKeyPefix) {
                            recordId =  Id.valueOf(recId.substringBefore('-').trim());
                            objectAPI = recordId.getSobjectType().getDescribe().getName();
                            parentIdWithObjectMap.put(recordId, objectAPI);
                        }
                    }
                }
            }

            // MR - Added for FRS-120-06
            if (att.Attachment_Type__c.equalsIgnoreCase('Registration')) {
                att.addError(System.Label.PreventRegistrationAttachmentDeletion);
            }
        }

        if (!parentIdWithObjectMap.isEmpty()) {
            Map<String, Set<String>> objectWithStatusMap = new Map<String, Set<String>>();
            for (Attachment_Workflow_Config__mdt attConfig : [
                SELECT Id, Is_Custom__c, Object_API_Name__c, Workflow_Status__c
                FROM Attachment_Workflow_Config__mdt
                WHERE Object_API_Name__c IN :parentIdWithObjectMap.values()
                AND Is_Custom__c = TRUE])
            {
                if (objectWithStatusMap.get(attConfig.Object_API_Name__c) == null) {
                    objectWithStatusMap.put(
                        attConfig.Object_API_Name__c,
                        new Set<String>{attConfig.Workflow_Status__c}
                    );
                } else {
                    Set<String> existingStatus = objectWithStatusMap.get(attConfig.Object_API_Name__c);
                    existingStatus.add(attConfig.Workflow_Status__c);
                    objectWithStatusMap.put(attConfig.Object_API_Name__c, existingStatus);
                }
            }


            for (Attachment__c att : (List<Attachment__c>)Trigger.old) {
                String ticketKeyPefix = CMPL123CME__Complaint__c.SObjectType.getDescribe().getKeyPrefix();
                if (String.isNotBlank(att.Parent_Id__c) || String.isNotBlank(att.Related_Parent_Id__c)) {
                    List<String> parentIDList = new List<String>((String.isNotBlank(att.Parent_Id__c)
                            ? att.Parent_Id__c.trim().split(' &&') : att.Related_Parent_Id__c.trim().split(' &&')));
                    Id recordId;
                    String status;

                    for (String recId : parentIDList) {
                        if (parentIDList.size() == 1 || (parentIDList.size() > 1 && recId.trim().substring(0,3) != ticketKeyPefix)) {
                            recordId =  Id.valueOf(recId.substringBefore('-').trim());
                            status = recId.substringAfter('-').trim();
                            if (status != null && status.length() > 0 && parentIdWithObjectMap.get(recordId) != null
                               && objectWithStatusMap.get(parentIdWithObjectMap.get(recordId)) != null
                               && !objectWithStatusMap.get(parentIdWithObjectMap.get(recordId)).contains(status)) {
                                   att.addError(System.Label.Custom_Attachment_Error_Message);
                               }
                        }
                    }

                }

            }
        }
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : validateAttachmentAvailability
    * @Invoke       : Events from TriggerHandler after insert, before Update
    * @Description  : To validate, send to CMSNext only if atatchment exists.
    * @Return       : N/A
    * @Params       : List<Attachment__c> newAttachmentList
    */
    private static void validateAttachmentAvailability(List<Attachment__c> newAttachmentList){
        Set<Id> recordWithAttachmentsSet = new Set<Id>();
        for (Attachment attObj : [SELECT Id, ParentId FROM Attachment WHERE ParentId IN : newAttachmentList]) {
            recordWithAttachmentsSet.add(attObj.ParentId);
        }

        for (Attachment__c attachmentObj : newAttachmentList) {
            if(attachmentObj.Send_to_CMSNext__c == true && (recordWithAttachmentsSet.isEmpty()
                    || !recordWithAttachmentsSet.contains(attachmentObj.Id))){
                attachmentObj.addError(System.Label.Attachment_Send_CMSNext_without_attachment);
            }
        }
    }


    /*
    * @Method       : afterDelete
    * @Invoke       : Events from TriggerHandler after delete
    * @Description  : To handle all the logic in after delete event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void afterDelete() {

    }


    /*
    * @Method       : preventTranslationAttachmentUpsertClosed
    * @Invoke       : Trigger
    * @Description  : To prevent Translation Task Attachment Upsert when Closed
    * @Return       : N/A
    * @Params       : List<Attachment__c> lstAttachments
    */
    private static void preventTranslationAttachmentUpsertClosed(List<Attachment__c> lstAttachments) {
        //Defect 181 Fix - Varsha Hariharan
        Set<String> eumirIds = new Set<String>();
        Map<Id, String> eumirMap = new Map<Id, String>();
        for(Attachment__c loopVar: lstAttachments){
            if(loopVar.EU_MIR__c != NULL){
                eumirIds.add(loopVar.EU_MIR__c);
            }
        }
        if(eumirIds.size() > 0){
            for(CMPL123CME__EU_MIR__c loopVar : [Select Id, CMPL123_WF_Status__c from CMPL123CME__EU_MIR__c where Id in: eumirIds])
            {
                eumirMap.put(loopVar.Id, loopVar.CMPL123_WF_Status__c);
            }
        }
        //Defect 181 Fix - End of changes - Varsha Hariharan
        if (ADDCustomAttachmentTriggerHandler.executeAttachmentFlag) {
            for (Attachment__c objAttachment : lstAttachments) {
                if (String.isNotBlank(objAttachment.Translation_Task__c) && String.isNotBlank(objAttachment.Parent_Id__c)
                   && (objAttachment.Parent_Id__c.contains('Closed-Done') || objAttachment.Parent_Id__c.contains('Closed-Voided'))) {
                    objAttachment.addError(System.Label.Custom_Attachment_Error_Message);
                   }
                //Defect 181 Fix - Varsha Hariharan
                if (String.isNotBlank(objAttachment.EU_MIR__c) && (eumirMap.get(objAttachment.EU_MIR__c).contains('Closed-Done') || eumirMap.get(objAttachment.EU_MIR__c).contains('Closed-Voided') || eumirMap.get(objAttachment.EU_MIR__c).contains('Closed - Waived'))) {
                    objAttachment.addError(System.Label.Custom_Attachment_Error_Message);
                }
                //Defect 181 Fix - End of Changes - Varsha Hariharan
            }
        }
    }

    /*
    * @Method       : preventCreatingDeletingIfParentIsSpecific
    * @Invoke       : Trigger
    * @Description  : To prevent Attachment's creation and deletion if has parents in specific statuses
    * @Return       : N/A
    * @Params       : List<Attachment__c> attachments
    */
    private static void preventCreatingDeletingIfParentIsSpecific(List<Attachment__c> attachments) {
        Map<Id, Attachment__c> pmraIdAttachment = new Map<Id, Attachment__c>();

        for (Attachment__c attachment :attachments) {
            if (null != attachment.Post_Market_Risk_Asst_Risk_Ctrl__c) {
                pmraIdAttachment.put(attachment.Post_Market_Risk_Asst_Risk_Ctrl__c, attachment);
            }
        }

        List<Post_Market_Risk_Assessment_Risk_Contr__c> pmras = [
            SELECT Id, CMPL123_WF_Status__c
            FROM Post_Market_Risk_Assessment_Risk_Contr__c
            WHERE Id IN :pmraIdAttachment.keySet()];

        for (Post_Market_Risk_Assessment_Risk_Contr__c pmra :pmras) {
            if (pmra.CMPL123_WF_Status__c == 'Pending Closure of Related Child Records and Tasks') {
                pmraIdAttachment.get(pmra.Id).addError(System.Label.Custom_Attachment_Error_Message);
            }
        }
    }

    /*
    * @Method       : updateCustomerResponse
    * @Invoke       : after insert or after update trigger events
    * @Description  : To update parent Customer Response Last_Modified_Date_Time__c
    * @Return       : N/A
    * @Params       : List<Attachment__c> lstAttachments
    */
     // CHaRM-R4: Commented the Method "updateCustomerResponse", Since the Last Modified Date and Time field will be
     // updated only on Assignee Name is Changed and Status is Closed-Done.
     // Moved the Logic to Flows "Update Last Modified Date And Time Field".
    //Def #146/CHARM-2791: added updateCustomerResponse method
   /* private static void updateCustomerResponse(List<Attachment__c> lstAttachments) {
        List<Customer_Response__c> responsesToUpdate = new List<Customer_Response__c>();
        if (!CustomerResponseTriggerHandler.isUpdated) {
            for (Attachment__c objAttachment : lstAttachments) {

                if (objAttachment.Customer_Response__c != null) {
                    responsesToUpdate.add(
                        new Customer_Response__c(
                            Id = objAttachment.Customer_Response__c,
                            Last_Modified_Date_Time__c = System.now()
                        )
                    );
                }
            }
        }
        CustomerResponseTriggerHandler.isLastModifiedDateUpdating = true;
        update responsesToUpdate;
        CustomerResponseTriggerHandler.isLastModifiedDateUpdating = false;
    }*///CHaRM-R4 Commented the Code 

    /*
    * @Method       : updateLastModifiedDateTime
    * @Description  : used to update custom Last Modified Date/Time field
    * @Return       : N/A
    * @Params       : N/A
    */
    static void updateLastModifiedDateTime() {
        if (Trigger.isBefore && UserInfo.getProfileId() != System.Label.Integration_Profile_ID) {
            for (Attachment__c attachment: (List<Attachment__c>)Trigger.new) {
                attachment.Last_Modified__c = System.now();
            }
        }
    }

    /*
    * @Method       : executeLogicFromWFRules.
    * @Description  : TWD Upgrade issue - this method contains logic from Workflow Rules with Field Updates on Attachment.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void executeLogicFromWFRules() {
        List<Attachment__c> newList = (List<Attachment__c>) Trigger.new;

        for (Attachment__c newAtt :newList) {
            //  Update registration attachement
            if (Trigger.isInsert && newAtt.Attachment_Type__c == 'Registration') {
                newAtt.Registartion_Attachment__c = newAtt.Name;
            }

            //  Update Last Modified
            newAtt.Last_Modified__c = DateTime.now();
        }
    }

    /**
     * @Description  : Used to create MDC record after Attachment is inserted.
     * See AttachmnetsWithTicketSearchMDCLogic and its affiliated MDC Trigger record
     * to see how MDCs are created when Attachments are updated rather than inserted.
     * MDC Triggers supposedly cannot make MDCs in response to a record insertion,
     * so this method was created by Orlando for defect 141.
     * @Revision     : 31-JAN-2023 Larry: Moved some logic to MDCTicketUtil since the
     * functionality was shared with TicketQDNumMDCCustom (which is also shared by seemingly
     * every MDC Trigger's field's dedicated class). This method's logic was largely
     * unchanged, but MDCs created for Attachments on a Ticket which have a related
     * Ticket Search now check that at least one of the Ticket Searches is active.
     */
    public void createMDCTicket(Map<Id,Attachment__c> attachmentNewMap) {
        Map <Id, Attachment__c> objMatchCon         = new Map <Id, Attachment__c>();
        Map <Id, Attachment__c> objMatchCondMedEval = new Map <Id, Attachment__c>();
        Map <Id, Attachment__c> objMatchCondInquiry = new Map <Id, Attachment__c>();
        Map <Id, Attachment__c> objMatchCondSearch  = new Map <Id, Attachment__c>();

        Set <Id> ticketIds = new Set <Id>();
        for (Attachment__c attachmentObj: attachmentNewMap.values()) {
            ticketIds.add(attachmentObj.Ticket__c);
        }
      
        Map<Id, Map<String, Boolean>> ticketMap = MDCTicketUtil.getParentTicketDetails(ticketIds);
		 // CHARM R9.0,IPDR-165: Retrieve Inquiry tickets that have a Customer Response for MDC Creation.
        List<CMPL123CME__Complaint__c> inquiryTicketsWithCR  = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Is_Custom_response_child_created__c = true AND RecordType.DeveloperName = 'Inquiry' AND Id IN :ticketIds];
        Map<Id,Boolean> inquiryTicketHasCRMap  = new Map<Id,Boolean>();
        for(CMPL123CME__Complaint__c comp:inquiryTicketsWithCR ){
            if(!inquiryTicketHasCRMap.ContainsKey(comp.Id))
                inquiryTicketHasCRMap.put(comp.Id,true);
        }
        for (Attachment__c attachmentObj: attachmentNewMap.values()) {
            if (attachmentObj.Ticket__c == null) {
                continue;
            }

            Map<String, Boolean> boolMap = ticketMap.get(attachmentObj.Ticket__c);
            if (boolMap.get(AspenConstants.TICKETFLAG_HAS_PRODEVAL)) {
                objMatchCon.put(attachmentObj.Id, attachmentObj);
            }

            if (boolMap.get(AspenConstants.TICKETFLAG_HAS_MEDEVAL)) {
                objMatchCondMedEval.put(attachmentObj.Id, attachmentObj);
            }
            // CHARM R9.0/IPDR-165: Added a check to Restrict MDC creation for Inquiry tickets without a Customer Response. 
            if (boolMap.get(AspenConstants.TICKETFLAG_IS_INQUIRY) && inquiryTicketHasCRMap.containsKey(attachmentObj.Ticket__c) && inquiryTicketHasCRMap.get(attachmentObj.Ticket__c)) {
                objMatchCondInquiry.put(attachmentObj.Id, attachmentObj);
            }
            if (boolMap.get(AspenConstants.TICKETFLAG_HAS_ACTIVE_TICKET_SEARCH)) {
                objMatchCondSearch.put(attachmentObj.Id, attachmentObj);
            }
        }

        final String RELATED_TICKET_ID_API = 'Ticket__c';
        final String RELATED_TICKET_NUM_API = 'Ticket_Number__c';
        final String AUDIT_ENTRY_FIELD = 'registartion_attachment__c';
        final Boolean IS_CREATE_JUNC = true;
        if (objMatchCon.size() > 0) {
            MDCTicketUtil.createMDC('Attachment Change for Evaluator/Investigator',
                objMatchCon, RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API,
                AUDIT_ENTRY_FIELD, IS_CREATE_JUNC);
        }

        if (objMatchCondMedEval.size() > 0) {
            MDCTicketUtil.createMDC('Attachment Change for Medical Evaluator',
                objMatchCondMedEval, RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API,
                AUDIT_ENTRY_FIELD, IS_CREATE_JUNC);
        }

        if (objMatchCondInquiry.size() > 0) {
            MDCTicketUtil.createMDC('Attachment Change for Quality non Complaint',
                objMatchCondInquiry, RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API,
                AUDIT_ENTRY_FIELD, IS_CREATE_JUNC);
        }

        if (objMatchCondSearch.size() > 0) {
            MDCTicketUtil.createMDC('Attachment change for FA Quality Assignee',
                objMatchCondSearch, RELATED_TICKET_ID_API, RELATED_TICKET_NUM_API,
                AUDIT_ENTRY_FIELD, IS_CREATE_JUNC);
        }
    }
}