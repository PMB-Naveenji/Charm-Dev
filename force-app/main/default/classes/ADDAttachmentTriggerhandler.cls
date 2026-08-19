/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDAttachmentTriggerhandler.
* @Why   : Handles all the customization involved on Attachment object.
* @When  : 25-FEB-2017.
* @Where : From AttachmentTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                    Modification ID         Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    25-FEB-2017             Work ID / Case ID       Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020             Code Audit              Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020             Code Audit              Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                    27-JUL-2020             Code Audit              Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                    08-SEP-2020             Code Audit              Added escapeSingleQuotes to preserveAttachments method query.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    15-SEP-2020             Defect #126             Added conditions to avoid Null pointer exception.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDAttachmentTriggerhandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert.
    * @Description  : To handle all the logic in before insert event.
    * @Invoke       : From AttachmentTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeInsert() {
        preventCreatingDeletingIfParentIsSpecific((List<Attachment>) Trigger.new);
        preventUploadOfAttachmentExcessFifteenMB();
        preventUploadOfAttachmentExceptBusinessAdmin();
        preserveAttachments((List<Attachment>) Trigger.new);
        createCustomAttachment((List<Attachment>) Trigger.new);
        preventUploadOfAttachmentOnEmdr();
        preventDeleteEditRMFAttachmentWhenParentClosed((List<Attachment>) Trigger.new);
        preventDeleteEditHHAAttachmentWhenParentClosed((List<Attachment>) Trigger.new);
    }

    /*
    * @Method       : beforeUpdate.
    * @Description  : To handle all the logic in before update event.
    * @Invoke       : From AttachmentTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeUpdate() {
        preserveAttachments((List<Attachment>) Trigger.new);
        preventUploadOfAttachmentOnEmdr();
        preventDeleteEditRMFAttachmentWhenParentClosed((List<Attachment>) Trigger.new);
        preventDeleteEditHHAAttachmentWhenParentClosed((List<Attachment>) Trigger.new);
    }

    /*
    * @Method       : beforeDelete.
    * @Description  : To handle all the logic in before delete event.
    * @Invoke       : From AttachmentTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeDelete() {
        preventCreatingDeletingIfParentIsSpecific((List<Attachment>) Trigger.old);
        preserveAttachments((List<Attachment>) Trigger.old);
        preventDeleteEditRMFAttachmentWhenParentClosed((List<Attachment>) Trigger.old);
        preventDeleteEditHHAAttachmentWhenParentClosed((List<Attachment>) Trigger.old);
    }

    /*
    * @Method       : afterDelete.
    * @Description  : To handle all the logic in after delete event.
    * @Invoke       : From AttachmentTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterDelete() {
        deleteCustomAttachments((List<Attachment>) Trigger.old);
    }

    /*
    * @Method       : deleteCustomAttachments.
    * @Description  : To delete custom attachments for EMDR.
    * @Invoke       : From ADDAttachmentTriggerhandler class.
    * @Return       : N/A.
    * @Params       : List<Attachment> attachmentsOldList.
    */
    public void deleteCustomAttachments(List<Attachment> attachmentsOldList){
        List<Id> attachmentsDeleteList = new List<Id>();
        String emdrKeyPefix = CMPL123CME__EMDR__c.SObjectType.getDescribe().getKeyPrefix();
        for (Attachment atch : attachmentsOldList) {
            if (String.valueOf(atch.ParentId).substring(0,3) == emdrKeyPefix) {
               attachmentsDeleteList.add(atch.ParentId);
            }
        }

        if (attachmentsDeleteList.size() > 0) {
            delete [SELECT Id FROM Attachment__c WHERE EMDR__c IN : attachmentsDeleteList];
        }
    }

    /*
    * @Method       : preserveAttachments.
    * @Description  : To preserve the list of attachments.
    * @Invoke       : From ADDAttachmentTriggerhandler class.
    * @Return       : N/A.
    * @Params       : List<Attachment> attachments.
    */
    public void preserveAttachments(List<Attachment> attachments) {
        Attachment att;
        Set<String> statusSet = new Set<String>();
        if (attachments != null && attachments.size() == 1) {
            for(Attachment attach : attachments) {
                att = attach;
                break;
            }

            String customAttKeyPefix = Attachment__c.SObjectType.getDescribe().getKeyPrefix();
            if (att.ParentId != null && String.valueOf(att.ParentId).substring(0,3) == customAttKeyPefix) {
                String parentId;

                if(System.Limits.getQueries() < System.Limits.getLimitQueries()){
                    for(Attachment__c attachmentObj : [SELECT Parent_Id__c, Related_Parent_Id__c FROM Attachment__c WHERE Id =:att.ParentId] ){
                        parentId = (String.isNotBlank(attachmentObj.Parent_Id__c) ? attachmentObj.Parent_Id__c : '') +''+(String.isNotBlank(attachmentObj.Related_Parent_Id__c) ? attachmentObj.Related_Parent_Id__c : '');
                    }
                } else {
                    att.addError(System.Label.Contact_Admin_Message + ':' + System.Label.SOQL_Limit_Message);
                }
                if(String.isNotBlank(parentId) && parentId.contains('-')) {

                    Map<Id,String> parentIdAndStatusMap = new Map<Id,String>();
                    for(String parentIdAndStatus : parentId.trim().split(' &&')){
                        parentIdAndStatusMap.put(Id.valueOf(parentIdAndStatus.substringBefore('-').trim()),
                                                 parentIdAndStatus.substringAfter('-').trim());
                    }
                    String ticketKeyPefix = CMPL123CME__Complaint__c.SObjectType.getDescribe().getKeyPrefix();
                    String objectAPI,status;
                    if(parentIdAndStatusMap.size() == 1){
                        Id parentRecordId = (new List<Id>(parentIdAndStatusMap.keySet()))[0];
                        objectAPI = parentRecordId.getSobjectType().getDescribe().getName();
                        status = parentIdAndStatusMap.get(parentRecordId);
                    }else{
                        for(Id atchParentId : parentIdAndStatusMap.keySet()){
                            if(String.valueOf(atchParentId).substring(0,3) != ticketKeyPefix){
                                objectAPI = atchParentId.getSobjectType().getDescribe().getName();
                                status = parentIdAndStatusMap.get(atchParentId);
                            }
                        }
                    }

                    for (Attachment_Workflow_Config__mdt attConfig : [SELECT Id, Is_Custom__c,
                                                                      Object_API_Name__c, Workflow_Status__c FROM Attachment_Workflow_Config__mdt
                                                                      WHERE Object_API_Name__c =:objectAPI]) {
                                                                          statusSet.add(attConfig.Workflow_Status__c);
                                                                      }
                    if (parentId.substringAfter('-').length() > 0 && !statusSet.contains(status) && status.length() > 0) {
                        att.addError(System.Label.Custom_Attachment_Error_Message);
                    }
                }
            } else {
                String objectAPI = att.ParentId.getSobjectType().getDescribe().getName();
                for (Attachment_Workflow_Config__mdt attConfig : [SELECT Id,
                                                                  Object_API_Name__c, Workflow_Status__c FROM Attachment_Workflow_Config__mdt
                                                                  WHERE Object_API_Name__c =:objectAPI AND Is_Custom__c = FALSE]) {
                                                                      statusSet.add(attConfig.Workflow_Status__c);
                                                                  }
                if (statusSet.size() > 0) {
                    String WFStatusField = objectAPI != null && objectAPI.contains('EMDR')
                            ? 'CMPL123CME__CMPL123_WF_Status__c'
                            : 'CMPL123_WF_Status__c';
                    String parentId = att.ParentId;
                    String queryString = 'SELECT Id,'+ WFStatusField + ' FROM ' + objectAPI;
                    queryString += ' WHERE Id = : parentId LIMIT 1';
                    SObject queriedRecord;
                    try {
                        queriedRecord = Database.query(String.escapeSingleQuotes(queryString));
                    } catch (QueryException qe) {
                        att.addError(System.Label.Contact_Admin_Message + ':' +qe.getMessage());
                    }
                    if (queriedRecord != null && queriedRecord.get(WFStatusField) != null
                         && !statusSet.contains(String.valueOf(queriedRecord.get(WFStatusField)))) {
                            att.addError(System.Label.Custom_Attachment_Error_Message);
                        }
                }
            }
        }
    }

    //W-000534 (Risk) "In the following states, we want the Business Admin ONLY to be able to attach emails for the purposes of attaching approvals via email
    /*
    * @Method       : preventUploadOfAttachmentExceptBusinessAdmin.
    * @Description  : To prevent the attachment upload except Business Admin.
    * @Invoke       : From ADDAttachmentTriggerhandler class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void preventUploadOfAttachmentExceptBusinessAdmin(){
        List<Attachment> lstAttachments = (List<Attachment>) Trigger.new;
        String strPostMarketPrefix = Post_Market_Risk_Assessment_Risk_Contr__c.SObjectType.getDescribe().getKeyPrefix();
        Set<Id> setPostMarketIds = new Set<Id>();
        for (Attachment objAttachment : lstAttachments) {
            if (String.valueOf(objAttachment.ParentId).startsWithIgnoreCase(strPostMarketPrefix)) {
                setPostMarketIds.add(objAttachment.ParentId);
            }
        }

        if (setPostMarketIds.size() > 0) {
            // Check whether user is Business Admin
            if ([SELECT COUNT() FROM GroupMember WHERE Group.Name = 'Business Admin' AND UserOrGroupId =: UserInfo.getUserId()] == 0) {
                for(Post_Market_Risk_Assessment_Risk_Contr__c objPostMarket : [SELECT Id FROM Post_Market_Risk_Assessment_Risk_Contr__c
                                                                                WHERE Id IN: setPostMarketIds
                                                                                AND (CMPL123_WF_Status__c = 'Pending Senior Management Approval'
                                                                                    OR CMPL123_WF_Status__c = 'Pending TSB - Senior Management Approval'
                                                                                    OR CMPL123_WF_Status__c = 'Pending Pass-Through Approval')]){
                    //Below Indexed line will not through error as we are checking size above only
                    lstAttachments[0].addError(System.Label.PreventAttachmentUpload);
                }
            }
        }
    }

    /*
    * @Method       : preventUploadOfAttachmentOnEmdr.
    * @Description  : FRS-1560-27 - to prevent the attachment upload except in Opened and MFR Report # Generated status.
    * @Invoke       : From ADDAttachmentTriggerhandler class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void preventUploadOfAttachmentOnEmdr() {
        List<Attachment> lstAttachments = (List<Attachment>) Trigger.new;
        String strEmdrPrefix = CMPL123CME__EMDR__c.SObjectType.getDescribe().getKeyPrefix();
        Set<Id> setEmdrIds = new Set<Id>();
        for (Attachment objAttachment : lstAttachments) {
            if (String.valueOf(objAttachment.ParentId).startsWithIgnoreCase(strEmdrPrefix)) {
                setEmdrIds.add(objAttachment.ParentId);
            }
        }

        if (setEmdrIds.size() > 0) {
            for (CMPL123CME__EMDR__c objEmdr : [SELECT Id FROM CMPL123CME__EMDR__c WHERE Id IN: setEmdrIds AND CMPL123CME__CMPL123_WF_Status__c != 'Opened' AND 
            CMPL123CME__CMPL123_WF_Status__c != 'MFR Report # Generated' LIMIT 1 ]) {
                lstAttachments[0].addError(System.Label.PreventAttachmentUploadOnEmdr);
            }
        }
    }

    // W-000211 Description - Creation of custom attachment and update parent of standard attachment when object is MEDDEV
    /*
    * @Method       : createCustomAttachment.
    * @Description  : To crate custom attachment and update parent of standard attachment when object is MEDDEV.
    * @Invoke       : From ADDAttachmentTriggerhandler class.
    * @Return       : N/A.
    * @Params       : List<Attachment> listAttachments.
    */
    private static void createCustomAttachment(List<Attachment> listAttachments) {
        List<Attachment__c> listattachmentToUpdate = new List<Attachment__c>();
        Map<String, Attachment> mapAttachments = new Map<String, Attachment>();
        //Added this code to add the Ticket lookup to the Custom Attachment for MEDDEV
        List<Id> medDevIdList = new List<Id>();
        List<Id> emdrIdList = new List<Id>();
        List<Id> eumirIdList = new List<Id>();

        if(listAttachments != null){
            for(Attachment objattach : listAttachments){
                if(objattach.ParentId.getSobjectType().getDescribe().getName() == 'CMPL123CME__MEDDEV__c'){
                    medDevIdList.add(objattach.ParentId);
                }else if(objattach.ParentId.getSobjectType().getDescribe().getName() == 'CMPL123CME__EMDR__c'){
                    emdrIdList.add(objattach.ParentId);
                }else if(objattach.ParentId.getSobjectType().getDescribe().getName() == 'CMPL123CME__EU_MIR__c'){
                    eumirIdList.add(objattach.ParentId);
                }
            }
            Map<Id,CMPL123CME__MEDDEV__c> medDevMap;
            if (medDevIdList.size() > 0 && Schema.SObjectType.CMPL123CME__MEDDEV__c.fields.CMPL123CME__Complaint__c.isAccessible()) {
                medDevMap = new Map<Id,CMPL123CME__MEDDEV__c>([SELECT Id,CMPL123CME__Complaint__c FROM CMPL123CME__MEDDEV__c
                                                                                            WHERE Id IN : medDevIdList]);

            }
            Map<Id,CMPL123CME__EU_MIR__c> eumirMap;
            if (eumirIdList.size() > 0 && Schema.SObjectType.CMPL123CME__EU_MIR__c.fields.CMPL123CME__Complaint__c.isAccessible()) {
                eumirMap = new Map<Id,CMPL123CME__EU_MIR__c>([SELECT Id,CMPL123CME__Complaint__c FROM CMPL123CME__EU_MIR__c
                                                                                            WHERE Id IN : eumirIdList]);

            }

            Map<Id, CMPL123CME__EMDR__c> emdrMap;
            if (emdrIdList.size() > 0 && Schema.SObjectType.CMPL123CME__EMDR__c.fields.CMPL123CME__Complaint__c.isAccessible()) {
                emdrMap = new Map<Id, CMPL123CME__EMDR__c>([SELECT Id,CMPL123CME__Complaint__c FROM CMPL123CME__EMDR__c
                                                                                            WHERE Id IN : emdrIdList]);
            }

            for (Attachment objattach : listAttachments) {
                //if(objattach.ParentId.getSObjectType().getDescribe().getName() == 'CMPL123CME__MEDDEV__c'){
                if(medDevIdList.contains(objattach.ParentId) || emdrIdList.contains(objattach.ParentId) || eumirIdList.contains(objattach.ParentId)){
                    Attachment__c objattachment = new Attachment__c ();
                    objattachment.Name = objattach.Name.length() > 80
                        ? objattach.Name.substring(0,80)
                        : objattach.Name;
                    objattachment.Attachment_Title__c = objattach.Name;
                    objattachment.Attachment_Type__c = 'Submission';
                    if(medDevIdList.contains(objattach.ParentId)){
                        if(!medDevMap.isEmpty() && medDevMap.containsKey(objattach.ParentId)){
                            objattachment.Ticket__c = medDevMap.get(objattach.ParentId).CMPL123CME__Complaint__c;
                        }
                        objattachment.MEDDEV__c = objattach.ParentId ;
                        mapAttachments.put(objattach.ParentId+objattach.Name, objattach);
                    }else if(emdrIdList.contains(objattach.ParentId)){
                        objattachment.Ticket__c = emdrMap.get(objattach.ParentId).CMPL123CME__Complaint__c;
                        objattachment.EMDR__c = objattach.ParentId;
                    }else if(eumirIdList.contains(objattach.ParentId)){
                        if(!eumirMap.isEmpty() && eumirMap.containsKey(objattach.ParentId)){
                            objattachment.Ticket__c = eumirMap.get(objattach.ParentId).CMPL123CME__Complaint__c;
                        }
                        objattachment.EU_MIR__c = objattach.ParentId ;
                        mapAttachments.put(objattach.ParentId+objattach.Name, objattach);
                    }
                    listattachmentToUpdate.add(objattachment);
                }
            }

        }

        if(listattachmentToUpdate.size() > 0){
            try{
                insert listattachmentToUpdate;
                for(Attachment__c objAttachment : listattachmentToUpdate){
                    if(!mapAttachments.isEmpty() && mapAttachments.containsKey(objAttachment.MEDDEV__c+objAttachment.Name)){
                        mapAttachments.get(objAttachment.MEDDEV__c+objAttachment.Name).ParentId = objAttachment.Id;
                    }
                    if(!mapAttachments.isEmpty() && mapAttachments.containsKey(objAttachment.EU_MIR__c+objAttachment.Name)){
                        mapAttachments.get(objAttachment.EU_MIR__c+objAttachment.Name).ParentId = objAttachment.Id;
                    }
                }
            }catch(Exception E){
                System.debug('=====E======='+E);
                if(E.getMessage().contains('Insufficient access')){
                    for(Attachment__c objAttachment : listattachmentToUpdate){
                        if(!mapAttachments.isEmpty() && mapAttachments.containsKey(objAttachment.MEDDEV__c+objAttachment.Name)){
                            mapAttachments.get(objAttachment.MEDDEV__c+objAttachment.Name).addError(System.Label.Custom_Attachment_Error_Message_based_on_Status);
                            return;
                        }
                        if(!mapAttachments.isEmpty() && mapAttachments.containsKey(objAttachment.EU_MIR__c+objAttachment.Name)){
                            mapAttachments.get(objAttachment.EU_MIR__c+objAttachment.Name).addError(System.Label.Custom_Attachment_Error_Message_based_on_Status);
                            return;
                        }
                    }
                }
            }

        }
    }

    /*
    * @Method       : afterInsert.
    * @Description  : To handle all the logic in after insert event.
    * @Invoke       : From AttachmentTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterInsert() {
        updateFileName((List<Attachment>) Trigger.new);
    }

    /*
    * @Method       : afterUpdate.
    * @Description  : To handle all the logic in after update event.
    * @Invoke       : From AttachmentTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterUpdate() {
        updateFileName((List<Attachment>) Trigger.new);
        updateCustAttachment((List<Attachment>) Trigger.new);
    }

    /*
    * @Method       : updateFileName.
    * @Description  : To update the file names in the list of Attachment.
    * @Invoke       : From ADDAttachmentTriggerhandler class.
    * @Return       : N/A.
    * @Params       : List<Attachment> attachments.
    */
    private static void updateFileName(List<Attachment> attachments){
        String customAttKeyPefix = Attachment__c.SObjectType.getDescribe().getKeyPrefix();
        List<Attachment__c> attachmentToUpdate = new List<Attachment__c>();
        Map<Id,String> customAttachmentIdMap = new Map<Id,String>();
        for(Attachment att : attachments){
            if (att.ParentId != null && String.valueOf(att.ParentId).substring(0,3) == customAttKeyPefix) {
                customAttachmentIdMap.put(att.ParentId,att.Name);
            }
        }
        if(customAttachmentIdMap != null && customAttachmentIdMap.size() > 0){
            for(Attachment__c attach : [SELECT Id, File_Name__c, Registration_Number__c,
                                        Attachment_Id__c,Customer_Response__c
                                        FROM Attachment__c WHERE Id IN : customAttachmentIdMap.keySet() ]){
                Attachment__c attachment = new Attachment__c();
                String fileName = customAttachmentIdMap != null && customAttachmentIdMap.containsKey(attach.Id)
                                 ? customAttachmentIdMap.get(attach.Id)
                                 : '';
                if(String.isNotBlank(attach.Registration_Number__c)){
                    String attachmentFileName = 'Att_'+attach.Registration_Number__c.substringBefore('(')+'-'+Datetime.now().format('yyyyMMddhhmmss')+'-'+fileName;
                    attachment.File_Name__c = attachmentFileName.replaceAll('(?i)[^a-z0-9\\.]', '_');
                    attachment.Send_to_CMSNext__c = false;
                    attachment.UNC_Path__c = '';
                    attachment.Attachment_Id__c = String.isNotBlank(attach.Attachment_Id__c) ? attach.Attachment_Id__c : attach.Id;
                    attachment.Id = attach.Id;
                    attachment.Attachment_Title__c = fileName;
                    if(attach.Customer_Response__c != null){
                       attachment.Name = fileName; //Added - 09MAY2019 - #747 CMSNext file not having extension
                    }
                    attachmentToUpdate.add(attachment);
                }
            }
        }

        if(attachmentToUpdate!= null && attachmentToUpdate.size() > 0){
            update attachmentToUpdate;
        }
    }

    /*
    * @Method       : updateCustAttachment.
    * @Description  : To update the attachment name if the name was changed.
    * @Invoke       : From ADDAttachmentTriggerhandler class.
    * @Return       : N/A.
    * @Params       : List<Attachment> attachments.
    */
    private static void updateCustAttachment(List<Attachment> attachments){
        List<Attachment__c> attachmentsList = new List<Attachment__c>();
        Map<Id,Attachment> attachmentIdAndValueMap = new Map<Id,Attachment>();
        String emdrKeyPefix = CMPL123CME__EMDR__c.SObjectType.getDescribe().getKeyPrefix();
        for(Attachment atch : attachments){
            if(String.valueOf(atch.ParentId).substring(0,3) == emdrKeyPefix
               && ((Map<Id,Attachment>)Trigger.oldMap).get(atch.Id).Name != atch.Name){
                attachmentIdAndValueMap.put(atch.ParentId,atch);
            }
        }

        if(attachmentIdAndValueMap.size() > 0){
            for(Attachment__c attachment : [SELECT Id,Name,Attachment_Title__c,EMDR__c FROM Attachment__c
                                            WHERE EMDR__c IN : attachmentIdAndValueMap.keySet()]){
                String fileName = attachmentIdAndValueMap.get(attachment.EMDR__c).Name;
                attachment.Name = fileName.length() > 80
                    ? fileName.substring(0,80)
                    : fileName;
                attachment.Attachment_Title__c  = fileName;
                attachmentsList.add(attachment);
            }
        }

        if(attachmentsList.size() > 0){
            update attachmentsList;
        }


    }

    /*
    * @Method       : stripExtension.
    * @Description  : To strip string extension.
    * @Invoke       : From ADDAttachmentTriggerhandler class.
    * @Return       : String s.
    * @Params       : String s.
    */
    public static String stripExtension(String s){
        return s != null && s.lastIndexOf('.') > 0
            ? s.substring(0, s.lastIndexOf('.'))
            : s;
    }

    //W-000054 - Prevent uploading attachment exceeding file size(18 MB)
    /*
    * @Method       : preventUploadOfAttachmentExcessFifteenMB.
    * @Description  : To prevent uploading attachment exceeding file size(18 MB).
    * @Invoke       : From ADDAttachmentTriggerhandler class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void preventUploadOfAttachmentExcessFifteenMB(){
        List<Attachment> lstAttachments = (List<Attachment>) Trigger.new;
        String strCustomAttachmentKeyPefix = Attachment__c.SObjectType.getDescribe().getKeyPrefix();
        String strTranslationTaskKeyPefix = Translation_Task__c.SObjectType.getDescribe().getKeyPrefix();
        String StrCustomerResponseKeyPrefix = Customer_Response__c.SObjectType.getDescribe().getKeyPrefix();
        Set<Id> setCustomAttachmentIds = new Set<Id>();

        for(Attachment objAttachment : lstAttachments){
            if (objAttachment.ParentId != null
                && String.valueOf(objAttachment.ParentId).substring(0,3) == strCustomAttachmentKeyPefix) {
                setCustomAttachmentIds.add(objAttachment.ParentId);
            }

        }
        Map<Id,Attachment__c> mapAttachments = new Map<Id,Attachment__c>([SELECT Id,Translation_Task__c,
                                                                          Customer_Response__c,Regulatory_Task__c,
                                                                          MEDDEV__c, EU_MIR__c,
                                                                          (SELECT Id FROM Attachments)
                                                                          FROM Attachment__c
                                                                          WHERE Id IN: setCustomAttachmentIds
                                                                          ]);  //AND Translation_Task__c != null

        for(Attachment objAttachment : lstAttachments) {
            Integer intSizeCheck = objAttachment.Body.size();

            if(intSizeCheck > 18000000 && objAttachment.ParentId != null
               && (String.valueOf(objAttachment.ParentId).substring(0,3) == strTranslationTaskKeyPefix
                   || (!mapAttachments.isEmpty() && setCustomAttachmentIds.size() > 0 &&
                       String.valueOf(objAttachment.ParentId).substring(0,3) == strCustomAttachmentKeyPefix
                       && mapAttachments.get(objAttachment.ParentId).Translation_Task__c != null
                       && String.valueOf(mapAttachments.get(objAttachment.ParentId).Translation_Task__c).substring(0,3) == strTranslationTaskKeyPefix))) {
                           objAttachment.addError(System.Label.Attachment_Maximum_size_is_15_MB);
            }
      //Defect #126. Added new condition objAttachment.ParentId !=null &&
            if(objAttachment.ParentId != null && String.valueOf(objAttachment.ParentId).substring(0,3) == strCustomAttachmentKeyPefix
               && !mapAttachments.isEmpty() && mapAttachments.get(objAttachment.ParentId).Customer_Response__c != null
               && String.valueOf(mapAttachments.get(objAttachment.ParentId).Customer_Response__c).substring(0,3) == StrCustomerResponseKeyPrefix
               && objAttachment.Name.length() > 64){ //Added - 09MAY2019 - #747 CMSNext file not having extension
                   objAttachment.addError(System.Label.Attachment_Name_Size_Error_For_Customer_Response);
            }


            // Added this code for #471 issue. //Defect #126. Added new condition objAttachment.ParentId !=null &&
            if(objAttachment.ParentId != null && String.valueOf(objAttachment.ParentId).substring(0,3) == strCustomAttachmentKeyPefix
               && !mapAttachments.isEmpty() && (mapAttachments.get(objAttachment.ParentId)).Attachments.size() == 1
               //&& (mapAttachments.get(objAttachment.ParentId).Regulatory_Task__c == null && mapAttachments.get(objAttachment.ParentId).MEDDEV__c == null)
              ){
                  objAttachment.addError(System.Label.Standard_Attachment_Limit);
              }

        }
    }

    /*
    * @Method       : preventDeleteEditRMFAttachmentWhenParentClosed.
    * @Description  : #DEF1118 - to prevent Delete/Edit RMF Attachment when parent or grandparent is closed.
    * @Invoke       : From ADDAttachmentTriggerhandler class.
    * @Return       : N/A.
    * @Params       : List<Attachment> lstAttachments.
    */
    private static void preventDeleteEditRMFAttachmentWhenParentClosed(List<Attachment> lstAttachments){
        String strAttKeyPefixRMF = RMF__c.SObjectType.getDescribe().getKeyPrefix();
        Set<Id> setRMFIds = new Set<Id>();
        for(Attachment objAttachment : lstAttachments){
            if (objAttachment.ParentId != null && String.valueOf(objAttachment.ParentId).substring(0,3) == strAttKeyPefixRMF) {
                setRMFIds.add(objAttachment.ParentId);
            }
        }

         if(setRMFIds.size() > 0){
            for(RMF__c objRMF : [SELECT Id FROM RMF__c WHERE Id IN: setRMFIds AND Parent_WF_status__c = TRUE LIMIT 1]){
                lstAttachments[0].addError(System.Label.Custom_Attachment_Error_Message);
            }
        }
    }

    /*
    * @Method       : preventDeleteEditHHAAttachmentWhenParentClosed.
    * @Description  : #DEF1212 - prevent Delete/Edit HHA Attachment when parent or grandparent is closed.
    * @Invoke       : From ADDAttachmentTriggerhandler class.
    * @Return       : N/A.
    * @Params       : List<Attachment> lstAttachments.
    */
    private static void preventDeleteEditHHAAttachmentWhenParentClosed(List<Attachment> lstAttachments){
        String strAttKeyPefixHHA = Health_Hazard_Assessment__c.SObjectType.getDescribe().getKeyPrefix();
        Set<Id> setHHAIds = new Set<Id>();
        for(Attachment objAttachment : lstAttachments){
            if (objAttachment.ParentId != null && String.valueOf(objAttachment.ParentId).substring(0,3) == strAttKeyPefixHHA) {
                setHHAIds.add(objAttachment.ParentId);
            }
        }

         if(setHHAIds.size() > 0){
            for(Health_Hazard_Assessment__c objHHA : [SELECT Id FROM Health_Hazard_Assessment__c WHERE Id IN: setHHAIds AND Parent_WF_status__c = TRUE LIMIT 1]){
                lstAttachments[0].addError(System.Label.Custom_Attachment_Error_Message);
            }
        }
    }

    /*
    * @Method       : preventCreatingDeletingIfParentIsSpecific.
    * @Description  : To prevent Attachment's creation and deletion if has parents in specific statuses.
    * @Invoke       : From ADDAttachmentTriggerhandler class.
    * @Return       : N/A.
    * @Params       : List<Attachment__c> attachments.
    */
    private static void preventCreatingDeletingIfParentIsSpecific(List<Attachment> attachments) {
        String customAttachObj = Attachment__c.SObjectType.getDescribe().getKeyPrefix();
        Map<Id, Attachment> attachmentMapIds = new Map<Id, Attachment>();

        for (Attachment attachment :attachments) {
            if (null != attachment.ParentId && String.valueOf(attachment.ParentId).substring(0, 3) == customAttachObj) {
                attachmentMapIds.put(attachment.ParentId, attachment);
            }
        }

        List<Attachment__c> customAttachments = [SELECT Id, Post_Market_Risk_Asst_Risk_Ctrl__c,
                                                        Post_Market_Risk_Asst_Risk_Ctrl__r.CMPL123_WF_Status__c
                                                    FROM Attachment__c
                                                    WHERE Id IN :attachmentMapIds.keySet()];

        for (Attachment__c attachment :customAttachments) {
            Boolean hasNeededPMRA = null != attachment.Post_Market_Risk_Asst_Risk_Ctrl__c
                    && attachment.Post_Market_Risk_Asst_Risk_Ctrl__r.CMPL123_WF_Status__c == 'Pending Closure of Related Child Records and Tasks';

            if (hasNeededPMRA) {
                attachmentMapIds.get(attachment.Id).addError(System.Label.Custom_Attachment_Error_Message);
            }
        }
    }
}