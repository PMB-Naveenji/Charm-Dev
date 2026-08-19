/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : ADDTranslations.
 * @Why   : Handles all the customization involved on Translations.
 * @When  : 06-APR-2017.
 * @Where : From ADDPatientInformationTriggerHandler class,ADDpREInformationTriggerHandler class, ADDReopenJustificationTriggerHandler class,
 *          ADDS4TranslationTaskTiggerHandler class, ADDTicketNoteTriggerhandler class, ComplaintTriggerHandler class, ADDMeaningfulDataTriggerHandler class,
 *          CMPL123CME_Complaint_AuditTrigger trigger, Customer_Response_AuditTrigger trigger, reopenJustificationTrigger trigger.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID                   Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                    06-APR-2017            Work ID / Case ID                 Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                    07-APR-2020            Defect #59                        Added Patient Info tracking for translation items creating.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    04-JUN-2020            Code Audit                        Removed 'System.debug()'.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    15-JUN-2020            Code Audit                        Removed commented code. Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    02-JUL-2020            Code Audit                        Added methods comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * vkaih                    17-AUG-2020            Code Audit                        Updated class comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    07-SEP-2020            Code Audit                        Added 'escapeSingleQuotes()' method call.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    16-NOV-2020            Defect #62 / CHARM-3356           Modified 'createTranslationTaskWhenTicketConverts()' method.
 *                                                                                       Removed loop and condition to filter ticket ids.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             09-MAY-2023            R3.1, IPDR 116                    updateApprovedTranslations no longer crashes due to a Translation Item
 * trying to update a "Closed-Voided" Customer Response. Replaced many magic words with constants
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

public class ADDTranslations {
    private static final String SOBJ_TICKET = 'CMPL123CME__Complaint__c';
    public static Map<String, String> countryNameWithId = null;
    public static Map<String, String> recordTypeNameWithIdMap;
    //Added - W-000313
    private static Boolean isExecuted = false;
    public static Boolean isExecutedTextAttachment = false;
    public static Boolean isExecutedFileAttachment = false;
    //Added - W-000313

    private static Map<String, List<Translation_Fields__mdt>> objectTFMap = null;
    static Schema.SObjectType preInfoObjType = pRE_Information__c.SObjectType;
    static Schema.DescribeSObjectResult patientInfoObjDescribe = Schema.SObjectType.Patient_Information__c;
    static Schema.DescribeFieldResult preInfoLookupDescribe =  Patient_Information__c.pRE_Information__c.getDescribe();
    static Schema.DescribeFieldResult complaintLookupDescribe = pRE_Information__c.Complaint__c.getDescribe();

    // R3.1, Larry: Made this shared logic be an accessor with automatic defaults
    @testVisible private static Map<String, Translation_Fields__mdt> labelToTransFieldMdt {
        get {
            if (labelToTransFieldMdt == null) {
                // getAll returns a map of DeveloperName to Translation_Field__mdt records.
                // We need a map of MasterLabel to Translation_Field__mdt records.
                Map<String, Translation_Fields__mdt> temp = new Map<String, Translation_Fields__mdt>();
                for (Translation_Fields__mdt trans : Translation_Fields__mdt.getAll().values()) {
                    temp.put(trans.MasterLabel, trans);
                }
                labelToTransFieldMdt = temp;
            }
            return labelToTransFieldMdt;
        }
        private set;
    }

    /*
    * @Method       : createTranslationTask.
    * @Description  : To handle creation of the translation task only if translated fields have data.
    * @Invoke       : From CMPL123CME_Complaint_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void createTranslationTask() {
        TicketUtil.addTrace('ADDTranslations.createTranslationTask');
        Map<Id, Translation_Task__c> newTranslationMap = new Map<Id, Translation_Task__c>();
        Map<Id, List<Translation_Item__c>> newTranslationItemMap = new Map<Id, List<Translation_Item__c>>();
        List<CMPL123CME__Complaint__c> tickets = (List<CMPL123CME__Complaint__c>) Trigger.new;
        Map<String, String> translationFieldMap = new Map<String, String>();
        setDefaults();
        for (Translation_Fields__mdt field : objectTFMap.get(SOBJ_TICKET)) {
            String devName = field.DeveloperName;
            translationFieldMap.put(
                devName.endsWith('_c')
                ? devName.replace(
                    devName.substring(devName.length() - 2,
                    devName.length()),'__c')
                : devName,
                field.MasterLabel
            );
        }
        for (CMPL123CME__Complaint__c ticket : tickets) {

            if (ticket.Country_of_origin__c != null
                    && (countryNameWithId.containsKey(ticket.Country_of_origin__c + '-' + ticket.Division__c)
                    || (ticket.Translation_Required_flag__c))
                    && ((ticket.RecordTypeId == recordTypeNameWithIdMap.get(AspenConstants.STR_Complaint))
                    || (ticket.RecordTypeId == recordTypeNameWithIdMap.get(AspenConstants.STR_Service)
                    && ticket.pRE_Status__c == AspenConstants.STR_Yes)
                    || (ticket.RecordTypeId == recordTypeNameWithIdMap.get(AspenConstants.STR_Inquiry) &&
                    ticket.Customer_Reply_Required__c))) {
                List<Translation_Item__c> tItems = new List<Translation_Item__c>();

                for (String fieldAPI : translationFieldMap.keySet()) {
                    if(ticket.get(fieldAPI)!= null && translationFieldMap.get(fieldAPI) != null) {
                        tItems.add(new Translation_Item__c (
                                Field_Name__c = translationFieldMap.get(fieldAPI),
                                Native__c = String.valueOf(ticket.get(fieldAPI)),
                                Related_Record_Id__c = ticket.Id
                        ));
                    }
                }

                if (tItems.size() > 0) {
                    newTranslationMap.put(ticket.Id, new Translation_Task__c(
                            Parent_Ticket__c = ticket.Id,
                            RecordTypeId = Schema.SObjectType.Translation_Task__c
                                .getRecordTypeInfosByName().get(AspenConstants.STR_Text_Translation)
                                .getRecordTypeId()
                    ));
                    newTranslationItemMap.put(ticket.Id, tItems);
                }
            }
        }

        List<Translation_Item__c> sobjList = new List<Translation_Item__c>();

        if (newTranslationMap.keySet().size() > 0) {
            insert newTranslationMap.values();
            for (Translation_Task__c tTask : newTranslationMap.values()) {
                for (Translation_Item__c tItem : newTranslationItemMap.get(tTask.Parent_Ticket__c)) {
                    tItem.Translation_Task__c = tTask.Id;
                    sobjList.add(tItem);
                }
            }
            if (sobjList.size() > 0) {
                insert sobjList;
            }
        }
    }

    /**
     * @Method       : processReopenJustification.
     * @Description  : To insert Translation tickets.
     * @Invoke       : From ADDTranslations class.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Commented this function because it is
     * dead code. Only the trigger called this function, but that call was
     * commented for "#716". Its functionality is probably handled in TicketServiceHandler.
     */
    // public static void processReopenJustification() {
    //     Map<Id,CMPL123CME__Complaint__c> oldComplaintsMap = (Map<Id,CMPL123CME__Complaint__c>)Trigger.oldMap;
    //     List<CMPL123CME__Complaint__c> tickets = (List<CMPL123CME__Complaint__c>) Trigger.new;
    //     List<Re_Open_Justification__c> reopenJustificationObjList = new List<Re_Open_Justification__c>();

    //     for (CMPL123CME__Complaint__c ticket : tickets){
    //         if(ticket.CMPL123CME__CMPL123_WF_Status__c != oldComplaintsMap.get(ticket.Id).CMPL123CME__CMPL123_WF_Status__c
    //                 && ticket.CMPL123CME__CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Reopen_Trans_Req
    //                 && (ticket.CMPL123CME__CMPL123_WF_Status__c == AspenConstants.STR_WF_Opened || ticket.CMPL123CME__CMPL123_WF_Status__c == AspenConstants.STR_WF_Reg_Closed)){
    //             if(ticket.Country_of_origin__c != null
    //                     && (countryNameWithId.containsKey(ticket.Country_of_origin__c + '-' + ticket.Division__c)
    //                     || (ticket.Translation_Required_flag__c))
    //                     && ((ticket.RecordTypeId == recordTypeNameWithIdMap.get(AspenConstants.STR_Complaint))
    //                     || (ticket.RecordTypeId == recordTypeNameWithIdMap.get(AspenConstants.STR_Service)
    //                     && ticket.pRE_Status__c == AspenConstants.STR_Yes)
    //                     || (ticket.RecordTypeId == recordTypeNameWithIdMap.get(AspenConstants.STR_Inquiry) &&
    //                     ticket.Customer_Reply_Required__c))) {

    //                 Re_Open_Justification__c reopenJustificationObj = CreateReopenJustification(ticket);
    //                 reopenJustificationObjList.add(reopenJustificationObj);
    //             }else{
    //                 ticket.addError(System.Label.Translation_Required_on_Re_Open);
    //             }

    //         }
    //     }
    //     if(reopenJustificationObjList.size() > 0){
    //         insert reopenJustificationObjList;
    //     }
    // }

    /**
     * @Method       : CreateReopenJustification.
     * @Description  : To create new Reopen Justification record without insert operation.
     * @Invoke       : From ADDTranslations class.
     * @Return       : Re_Open_Justification__c reopenJustificationObj.
     * @Params       : CMPL123CME__Complaint__c ticket.
     * @Revision     : R3.1, Larry: Commented this function because it is
     * dead code. It is a helper function for the now-commented processReopenJustification
     */
    // public static Re_Open_Justification__c CreateReopenJustification(CMPL123CME__Complaint__c ticket) {
    //     Re_Open_Justification__c reopenJustificationObj = new Re_Open_Justification__c();
    //     reopenJustificationObj.Re_Open_Rationale_Created_On__c = System.Datetime.now();
    //     reopenJustificationObj.Re_Open_Rationale_Created_By__c = UserInfo.getName();
    //     reopenJustificationObj.Ticket_Re_Open_Rationale_Native__c = ticket.Reopen_Rationale__c != null && ticket.Reopen_Rationale__c.length() > 255
    //             ? ticket.Reopen_Rationale__c.substring(0,255)
    //             : ticket.Reopen_Rationale__c;
    //     reopenJustificationObj.Complaint__c = ticket.Id;
    //     return reopenJustificationObj;
    // }

    /*
    * @Method       : ChildObjectTranslations.
    * @Description  : To handle creation of the translation task only if translated fields have data.
    * @Invoke       : From ADDPatientInformationTriggerHandler class,ADDpREInformationTriggerHandler class, ADDReopenJustificationTriggerHandler class,
    *                 ADDTicketNoteTriggerhandler class, ADDMeaningfulDataTriggerHandler class, CMPL123CME_Complaint_AuditTrigger trigger,
    *                 Customer_Response_AuditTrigger trigger, reopenJustificationTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void ChildObjectTranslations() {
        TicketUtil.addTrace('ADDTranslations.ChildObjectTranslations');
        Map<Id, SObject> newMap = Trigger.newMap;
        Map<Id, SObject> oldMap = Trigger.oldMap;

        Set<String> ticketIds = new Set<String>();
        Map<Id, Translation_Task__c > ticketIdWithTask = new Map<Id, Translation_Task__c >();
        Map<Id, List<Translation_Item__c>> ticketWithItemsMap = new Map<Id, List<Translation_Item__c>>();
        Map<String, String> fieldApiWithLabel = new Map<String, String>();
        String relatedTicketAPIName, objectAPI;
        Map<String, Id> existingItemMap = new Map<String, Id>();

        for (Id currentRecordId : newMap.keySet()) {
            if(objectAPI == null) {
                objectAPI = currentRecordId.getSobjectType().getDescribe().getName();
                break;
            }
        }

        setDefaults();

        // R3.1, Larry: TODO: Why does this happen twice? There is room for concision
        for (Id currentRecordId : newMap.keySet()) {
            if(objectAPI == null) {
                objectAPI = currentRecordId.getSobjectType().getDescribe().getName();
                break;
            }
        }

        for (Translation_Fields__mdt field : objectTFMap.get(objectAPI)) {
            String devName = field.DeveloperName;
            fieldApiWithLabel.put(devName.endsWith('_c')
                ? devName.replace(
                    devName.substring(devName.length() - 2,
                    devName.length()),'__c'
                )
                : devName,
                field.MasterLabel
            );
            if (relatedTicketAPIName == null) {
                relatedTicketAPIName = field.Related_Complaint_API__c;
            }
        }

        // Check whether Translation is Required or Not
        Set<String> ticketsRequiringTranslationSet = new Set<String>();
        String ticketIdStr = '';
        for (SObject currentRecord : newMap.values()) {
            ticketIdStr = currentRecord.get(relatedTicketAPIName) + '';

            // Collect the Ticket Ids
            ticketIds.add(ticketIdStr);

            // R3.1, Larry: TODO: String.valueOf and Map.get are slow. Are these really necessary?
            if(objectAPI == SOBJ_TICKET &&
                String.valueOf(currentRecord.get('Translation_Required_flag__c')) != String.valueOf(Trigger.oldMap.get(ticketIdStr).get('Translation_Required_flag__c')) &&
                Boolean.valueOf(currentRecord.get('Translation_Required_flag__c'))) {
                ticketsRequiringTranslationSet.add(ticketIdStr);
            }
        }

        // 12APR19 - Added Where Id IN :ticketIds AND CMPL123CME__CMPL123_WF_Status__c NOT LIKE 'Closed%'] for Ticket Reopen
        Map<Id, CMPL123CME__Complaint__c> complaintMap = new Map<Id, CMPL123CME__Complaint__c>(
        [SELECT Id, Division__c, Country_of_origin__c, pRE_Status__c, Customer_Reply_Required__c,
                Ticket_Type__c, Translation_Required_flag__c, RecordTypeId
        FROM CMPL123CME__Complaint__c
        WHERE Id IN :ticketIds AND (NOT CMPL123CME__CMPL123_WF_Status__c LIKE 'Closed%')]
        );

        for(CMPL123CME__Complaint__c ticketRecord : complaintMap.values()) {
            // Added - W-000110 - (ticket.Translation_Required_flag__c == true)
            if (ticketRecord.Country_of_origin__c != null
                    && (countryNameWithId.containsKey(ticketRecord.Country_of_origin__c + '-' + ticketRecord.Division__c)
                    ||(ticketRecord.Translation_Required_flag__c))
                    && ((ticketRecord.RecordTypeId == recordTypeNameWithIdMap.get(AspenConstants.STR_Complaint))
                    || (ticketRecord.RecordTypeId == recordTypeNameWithIdMap.get(AspenConstants.STR_Service)
                    && ticketRecord.pRE_Status__c == AspenConstants.STR_Yes)
                    || (ticketRecord.RecordTypeId == recordTypeNameWithIdMap.get(AspenConstants.STR_Inquiry) &&
                    ticketRecord.Customer_Reply_Required__c))) {
                ticketsRequiringTranslationSet.add(ticketRecord.Id);

                // Added - W-000110 - (ticket.Translation_Required_flag__c == true)
                if(!ticketIdWithTask.containsKey(ticketRecord.Id)) {
                    ticketIdWithTask.put(ticketRecord.Id,
                            new Translation_Task__c(
                                    Parent_Ticket__c = ticketRecord.Id,
                                    RecordTypeId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName()
                                        .get(AspenConstants.STR_Text_Translation).getRecordTypeId()
                            ));
                }
            }
        }

        if(ticketIdWithTask.size() > 0) {
            // If insert just create the Translation Items
            // If Update check whether the translation fields are modified
            for (Translation_Task__c  tTask : [SELECT Id, Name, Parent_Ticket__c,
                (SELECT Id, Native__c, Field_Name__c, Related_Record_Id__c
                FROM Translation_Items__r)
                FROM Translation_Task__c
                WHERE Parent_Ticket__c  IN : ticketIds
                AND RecordType.Name = :AspenConstants.STR_Text_Translation
                AND (CMPL123_WF_Status__c = :AspenConstants.STR_WF_Opened
                OR CMPL123_WF_Status__c = :AspenConstants.STR_In_Process) ORDER BY Name
            ]) {
                ticketIdWithTask.put(tTask.Parent_Ticket__c, tTask);
                for (Translation_Item__c t : tTask.Translation_Items__r) {
                    existingItemMap.put(t.Related_Record_Id__c + '-' + t.Field_Name__c, t.Id);
                }
            }

            for (Id recordId : newMap.keySet()) {
                SObject sObj = newMap.get(recordId);
                SObject oldObj = oldMap == null ? null : oldMap.get(recordId);

                String relatedTicketId = sObj.get(relatedTicketAPIName) != null
                        ? String.valueOf(sObj.get(relatedTicketAPIName))
                        : null;

                if(ticketsRequiringTranslationSet.contains(relatedTicketId) || ticketIdWithTask.containsKey(relatedTicketId)) {
                    for (String fieldAPI : fieldApiWithLabel.keySet()) {
                        String fieldLabel = fieldApiWithLabel.get(fieldAPI);

                        //Added - W-000110
                        if (sObj.get(fieldAPI) != null && fieldLabel != null
                                && (oldObj == null || (oldObj != null && sObj.get(fieldAPI) != oldObj.get(fieldAPI)))) {
                            String relatedIdWithField = String.valueOf(sObj.get('Id'))+ '-' + fieldLabel;
                            Id exsitingItemId = existingItemMap.get(relatedIdWithField);

                            if (ticketWithItemsMap.get(relatedTicketId) == null) {
                                ticketWithItemsMap.put(relatedTicketId, new List<Translation_Item__c>{
                                        new Translation_Item__c (
                                                Field_Name__c = fieldLabel,
                                                Native__c = String.valueOf(sObj.get(fieldAPI)),
                                                Related_Record_Id__c = String.valueOf(sObj.get('Id')),
                                                Id = exsitingItemId
                                        )
                                });
                            } else {
                                List<Translation_Item__c> tItems = ticketWithItemsMap.get(relatedTicketId);
                                tItems.add (
                                        new Translation_Item__c (
                                                Field_Name__c = fieldLabel,
                                                Native__c = String.valueOf(sObj.get(fieldAPI)),
                                                Related_Record_Id__c = String.valueOf(sObj.get('Id')),
                                                Id = exsitingItemId
                                        )
                                );
                                ticketWithItemsMap.put(relatedTicketId, tItems);
                            }
                        }
                    }
                }
            }
        }

        for (Id ticketId : ticketIdWithTask.keySet()) {
            if (!(ticketWithItemsMap.get(ticketId) != null && ticketWithItemsMap.get(ticketId).size() > 0)) {
                ticketIdWithTask.remove(ticketId);
            }
        }
        if (ticketIdWithTask.keySet().size() > 0) {
            upsert ticketIdWithTask.values();
            List<Translation_Item__c> tItemList = new List<Translation_Item__c>();
            for (Id ticketId : ticketWithItemsMap.keySet()) {
                if (ticketIdWithTask.get(ticketId) != null && ticketIdWithTask.get(ticketId).Id != null) {
                    for (Translation_Item__c tItem : ticketWithItemsMap.get(ticketId)) {
                        tItem.Translation_Task__c = ticketIdWithTask.get(ticketId).Id;
                        tItemList.add(tItem);
                    }
                }
            }

            if (tItemList.size() > 0) {
                upsert tItemList;
            }
        }
    }

    /*
    * @Method       : createTranslationTaskWhenTicketConverts.
    * @Description  : 1. To include the original (earlier) non-english text items when converting an Inquiry ticket
    *                 with Customer Reply field = "No" to Inquiry ticket with a Customer Reply field = "Yes".
    *                 2. To include the original (earlier) non-english text items when converting a
    *                 service ticket to a pRE Service or Complaint ticket.
    * @Invoke       : From ADDTranslations class, ComplaintTriggerHandler class.
    * @Return       : N/A.
    * @Params       : List<CMPL123CME__Complaint__c> lstComplaints, Map<Id,CMPL123CME__Complaint__c> mapComplaintsOld.
    */
    public static void createTranslationTaskWhenTicketConverts(Set<Id> setComplaintIds) {
        TicketUtil.addTrace('ADDTranslations.createTranslationTaskWhenTicketConverts');
        if (isExecuted || setComplaintIds.isEmpty()) {
            return;
        }

        //construct parent child dynamic query based on custom metadata types
        Map<String, Set<String>> mapComplaintRelatedChildFields = new Map<String, Set<String>>();
        Map<String, Map<String,String>> mapRecordFields = new Map<String, Map<String,String>>();
        Map<String, String> mapObjNameToRelatedTicketName = new Map<String, String>();
        String patientInfoObjName = patientInfoObjDescribe.getName();
        Set<Id> preInfoIds = new Set<Id>();

        String strDynamicQuery = 'SELECT Id, Division__c, Country_of_origin__c, pRE_Status__c, Customer_Reply_Required__c,';
        strDynamicQuery += 'Ticket_Type__c, Translation_Required_flag__c, RecordTypeId ';

        for (Translation_Fields__mdt objTranslationField : [
            SELECT Id, DeveloperName, MasterLabel, Object_API__c, Child_Relationship__c,
                Related_Complaint_API__c
            FROM Translation_Fields__mdt
            WHERE Is_Adhoc__c = false
        ]) {
            String strObjectAPI = objTranslationField.Object_API__c;

            String devName = objTranslationField.DeveloperName;
            String strFieldAPIName = devName.endsWith('_c')
                ? devName.replace(
                    devName.substring(devName.length() - 2,
                    devName.length()),'__c')
                : devName;

            mapObjNameToRelatedTicketName.put(objTranslationField.Object_API__c, objTranslationField.Related_Complaint_API__c);

            if (objTranslationField.Child_Relationship__c != null) {
                String strChildRelationFieldAPI = objTranslationField.Child_Relationship__c+'__r';

                if (!mapComplaintRelatedChildFields.containsKey(strChildRelationFieldAPI)) {
                    mapComplaintRelatedChildFields.put(strChildRelationFieldAPI, new Set<String>{strFieldAPIName});
                } else {
                    mapComplaintRelatedChildFields.get(strChildRelationFieldAPI).add(strFieldAPIName);
                }
            }

            if ((objTranslationField.Child_Relationship__c == null && (objTranslationField.Object_API__c == SOBJ_TICKET
                    || objTranslationField.Object_API__c == patientInfoObjName)) || objTranslationField.Child_Relationship__c != null) {
                if (!mapRecordFields.containsKey(strObjectAPI)) {
                    Map<String,String> mapTemp = new Map<String,String>{strFieldAPIName => objTranslationField.MasterLabel};
                    mapRecordFields.put(strObjectAPI,mapTemp);
                } else {
                    mapRecordFields.get(strObjectAPI).put(strFieldAPIName,objTranslationField.MasterLabel);
                }
            }
        }

        for (String strKey : mapRecordFields.get(SOBJ_TICKET).keySet()) {
            strDynamicQuery += ', '+strKey;
        }

        for (String strKey :mapComplaintRelatedChildFields.keySet()) {
            String strInnerQuery = ', (SELECT ';

            for (String strField :mapComplaintRelatedChildFields.get(strKey)) {
                strInnerQuery += strField +' ,';
            }

            strInnerQuery = strInnerQuery.removeEnd(',')+' FROM '+strKey+')';

            strDynamicQuery += strInnerQuery;
        }

        strDynamicQuery += ' FROM CMPL123CME__Complaint__c WHERE Id IN: setComplaintIds ';

        Map<Id, List<SObject>> mapChildRecordsForTicket = new Map<Id, List<SObject>>();
        // get all child records data that used in translation
        for (SObject objComplaint :Database.query(String.escapeSingleQuotes(strDynamicQuery))) {
            for (String strKey :mapComplaintRelatedChildFields.keySet()) {
                List<SObject> childObjects = (List<SObject>) objComplaint.getSObjects(strKey);

                if (null == childObjects || childObjects.isEmpty()) {
                    continue;
                }

                for (SObject strObject :(List<SObject>) objComplaint.getSObjects(strKey)) {
                    if (!mapChildRecordsForTicket.containsKey(objComplaint.Id)) {
                        mapChildRecordsForTicket.put(objComplaint.Id, new List<SObject>{strObject});
                    } else {
                        mapChildRecordsForTicket.get(objComplaint.Id).add(strObject);
                    }

                    // Def #59 fix: process only necessary Patient Info records (where parentId is in preInfoIds set)
                    if (strObject.getSObjectType() == preInfoObjType) {
                        preInfoIds.add(strObject.Id);
                    }
                    // Def #59 fix end
                }
            }

            SObject objComplaintTemp = new CMPL123CME__Complaint__c(Id = objComplaint.Id);
            if (!mapRecordFields.isEmpty() && mapRecordFields.containsKey(SOBJ_TICKET)) {
                for (String strKey :mapRecordFields.get(SOBJ_TICKET).keySet()) {
                    objComplaintTemp.put(strKey, objComplaint.get(strKey));
                }

                if (!mapChildRecordsForTicket.containsKey(objComplaint.Id)) {
                    mapChildRecordsForTicket.put(objComplaint.Id, new List<SObject>{objComplaintTemp});
                } else {
                    mapChildRecordsForTicket.get(objComplaint.Id).add(objComplaintTemp);
                }
            }
        }

        // Def #59 fix: query Patient Info ticket grandchildren in order to track them for translation items creating
        if (preInfoIds.size() > 0) {
            String queryFormat = 'SELECT {0} FROM {1} WHERE {2} IN :setComplaintIds';
            String relatedTicket = mapObjNameToRelatedTicketName.get(patientInfoObjName);
            Set<String> trackedFields = mapRecordFields.get(patientInfoObjName).keySet();
            List<String> fieldsToQuery = new List<String>(trackedFields);

            if (!trackedFields.contains(relatedTicket)) {
                fieldsToQuery.add(relatedTicket);
            }

            List<String> arguments = new List<String>{
                String.join(fieldsToQuery, ' ,'),
                patientInfoObjName,
                String.join(new List<String> {
                    preInfoLookupDescribe.getRelationshipName(),
                    complaintLookupDescribe.getName()
                }, '.')
            };

            String queryStr = String.format(queryFormat, arguments);

            for (SObject sObjRecord :Database.query(queryStr)) {
                String ticketId = (String)sObjRecord.get(relatedTicket);

                if (!mapChildRecordsForTicket.containsKey(ticketId)) {
                    mapChildRecordsForTicket.put(ticketId, new List<SObject>{sObjRecord});
                } else {
                    mapChildRecordsForTicket.get(ticketId).add(sObjRecord);
                }
            }
        }
        // Def #59 fix end

        Map<Id, Translation_Task__c> mapTicketIdWithTasks = new Map<Id, Translation_Task__c>();
        Map<Id, List<Translation_Item__c>> mapTicketWithItems = new Map<Id, List<Translation_Item__c>>();
        Map<String, Id> mapExistingItems = new Map<String, Id>();

        for (Translation_Task__c objTranslationTask :[
            SELECT Id, Name, Parent_Ticket__c,
                (SELECT Id, Native__c, Field_Name__c, Related_Record_Id__c FROM Translation_Items__r)
            FROM Translation_Task__c
            WHERE Parent_Ticket__c IN: setComplaintIds
                AND RecordType.Name = :AspenConstants.STR_Text_Translation
                AND (CMPL123_WF_Status__c = :AspenConstants.STR_Opened
                    OR CMPL123_WF_Status__c= :AspenConstants.STR_In_Process)
        ]) {
            mapTicketIdWithTasks.put(objTranslationTask.Parent_Ticket__c , objTranslationTask);

            for (Translation_Item__c objTranslationItem :objTranslationTask.Translation_Items__r) {
                mapExistingItems.put(objTranslationItem.Related_Record_Id__c + '-' + objTranslationItem.Field_Name__c, objTranslationItem.Id);
            }
        }

        for (Id idTicket :setComplaintIds) {
            if (!mapTicketIdWithTasks.containsKey(idTicket)) {
                mapTicketIdWithTasks.put(idTicket,
                    new Translation_Task__c(
                        Parent_Ticket__c = idTicket,
                        RecordTypeId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName()
                            .get(AspenConstants.STR_Text_Translation).getRecordTypeId()
                    )
                );
            }
        }

        for (Id idTicket :mapChildRecordsForTicket.keySet()) {
            for (SObject objRecord :mapChildRecordsForTicket.get(idTicket)) {
                Map<String,String> mapFields = mapRecordFields.get(String.valueOf(objRecord.getSObjectType()));

                for (String strFieldAPI :mapFields.keySet()) {
                    if (objRecord.get(strFieldAPI) != null && mapFields.get(strFieldAPI) != null) {
                        String relatedIdWithField = objRecord.Id+ '-' + mapFields.get(strFieldAPI);

                        Id idExsitingItem = mapExistingItems.get(relatedIdWithField);

                        Translation_Item__c objTranslationItem = new Translation_Item__c(
                            Field_Name__c = mapFields.get(strFieldAPI),
                            Native__c = String.valueOf(objRecord.get(strFieldAPI)),
                            Related_Record_Id__c = objRecord.Id,
                            Id = idExsitingItem
                        );

                        if (!mapTicketWithItems.containsKey(idTicket)) {
                            mapTicketWithItems.put(idTicket, new List<Translation_Item__c>{objTranslationItem});
                        } else {
                            mapTicketWithItems.get(idTicket).add(objTranslationItem);
                        }
                    }
                }
            }

            List<Translation_Item__c> transItems = mapTicketWithItems.get(idTicket);

            if (!(transItems != null && !transItems.isEmpty())) {
                mapTicketIdWithTasks.remove(idTicket);
            }
        }

        if (mapTicketIdWithTasks.keySet().size() > 0) {
            upsert mapTicketIdWithTasks.values();

            List<Translation_Item__c> lstTranslationItems = new List<Translation_Item__c>();

            for (Id ticketId :mapTicketWithItems.keySet()) {
                Translation_Task__c transTask = mapTicketIdWithTasks.get(ticketId);

                if (transTask != null && transTask.Id != null) {
                    for (Translation_Item__c objTranslationItem : mapTicketWithItems.get(ticketId)) {
                        objTranslationItem.Translation_Task__c = transTask.Id;
                        lstTranslationItems.add(objTranslationItem);
                    }
                }
            }

            if (lstTranslationItems.size() > 0) {
                upsert lstTranslationItems;
            }
        }

        isExecuted = true;
    }

    /**
     * @Method       : updateApprovedTranslations.
     * @Description  : To update all the approved translation data to respective parent fields.
     * @Invoke       : From ADDS4TranslationTaskTiggerHandler class.
     * @Return       : A Map of Ids to any records that got updated.
     * @Params       : Set<String> translationTaskIds.
     * @Revision     : R3.1, Larry: No longer tries to update "Closed-Voided" Customer Responses.
     * Replaced custom metadata query with getAll(). Added comments to explain intentions and purposes.
     * Now returns the result of this function's processing for easier testing.
     */
    public static Map<Id, SObject> updateApprovedTranslations(Set<String> translationTaskIds) {
        TicketUtil.addTrace('ADDTranslations.updateApprovedTranslations');

        // R3.1, Larry: Note that fieldWithObjectMap was the old way that
        // lookups were performed on Translation_Field__mdt. The map values were
        // stringly-typed, so they needed to be built and decomposed when used.
        // This old code is commented out for reference in case my streamlined
        // approach is buggy.
        // Map<String, String> fieldWithObjectMap = new Map<String, String>();
        // for (Translation_Fields__mdt trans : Translation_Fields__mdt.getAll().values()) {
        //     fieldWithObjectMap.put(trans.MasterLabel, trans.Object_API__c + '-' + trans.Translated_Field_Name_API__c);
        // }

        // Translation_Item__c.Related_Record_Id__c is a STRING instead of a LOOKUP,
        // so it can point to ANY kind of SObject. This map stores all records
        // referenced by Translation Item children under the passed Translation Tasks.
        Map<Id, SObject> idToTranslatableRecord = new Map<Id, SObject>();
        Set<Id> parentTicketIdSet = new Set<Id>();
        // Fetch all Translation Items under the passed Translation Tasks
        for (Translation_Task__c translationTask : [
            SELECT Id, RecordType.Name, Parent_Ticket__c, (
                SELECT Id, Field_Name__c, Native__c, Related_Record_Id__c,
                Translated__c, Translation_Task__c, Is_Voided__c
                FROM Translation_Items__r
                WHERE Is_Voided__c = false)
            FROM Translation_Task__c
            WHERE Id IN :translationTaskIds AND
            RecordType.Name = :AspenConstants.STR_Text_Translation
            WITH SECURITY_ENFORCED
        ]) {
            // For the culling to happen later, track the Ticket Id
            parentTicketIdSet.add(translationTask.Parent_Ticket__c);

            // Copy the Translation Item's translated text into its referenced record's field
            for (Translation_Item__c tItem : translationTask.Translation_Items__r) {
                // R3.1, Larry: Inverted the if-statement to reduce scope.
                // Note that we cannot move Translated__c into the query because it is a long text area.
                if (String.isBlank(tItem.Translated__c)) {
                    continue;
                }

                idToTranslatableRecord.put(tItem.Related_Record_Id__c,
                    makeRecordToTranslate(tItem, idToTranslatableRecord));
            }
        }

        if (!idToTranslatableRecord.isEmpty()) {
            update idToTranslatableRecord.values();
            isExecutedTextAttachment = true;
        }
        return idToTranslatableRecord;
    }

    /**
     * Makes an arbitrary record and applies the passed translation
     * @param tItem Stores the translation to apply and knows where to put it. Cannot be null
     * @param idToTranslatableRecord Map of Ids to non-TranslationItem records. Map keys
     * are identical to tItem.Related_Record_Id__c, but not all tItems need to be
     * referenced in this map. This map cannot be null
     * @param fieldWithObjectMap DEPRECATED. Map of MasterLabel to TLField's "ObjectName-DestinationField"
     * @return A record with tItem's translation applied to one of its fields
     * @author R3.1, Larry Resnik
     */
    @testVisible
    private static SObject makeRecordToTranslate(
        Translation_Item__c tItem,
        Map<Id, SObject> idToTranslatableRecord
        // Map<String, String> fieldWithObjectMap
    ) {
        Id recordId = tItem.Related_Record_Id__c;
        SObject recordToTranslate = idToTranslatableRecord.get(recordId);

        // This custom metadata relates field API names for Native and Translated fields.
        // For example, the metadata record whose Dev Name is "Ticket_Notes_Native_c" (sic),
        // says the translated field is "Ticket_Notes_Translated__c".
        Translation_Fields__mdt transField = labelToTransFieldMdt.get(tItem.Field_Name__c);
        String objApiNameNewWay = transField?.Object_API__c;
        // String objApiNameOldWay = fieldWithObjectMap.get(tItem.Field_Name__c)?.substringBefore('-');

        // Create an arbitrary SObject from the related record Id
        if (recordToTranslate == null && objApiNameNewWay != null) {
            Schema.SObjectType sObj = Schema.getGlobalDescribe().get(objApiNameNewWay);
            recordToTranslate = sObj.newSObject();
            recordToTranslate.Id = recordId;
        }

        // Set the pointed-to record's "(Translated)" field to the value in the Translation Item.
        if (transField != null) {
            String destinationFieldNameNewWay = transField.Translated_Field_Name_API__c;
            // String destinationFieldNameOldWay = fieldWithObjectMap.get(tItem.Field_Name__c)?.substringAfter('-');
            recordToTranslate.put(destinationFieldNameNewWay, tItem.Translated__c);
        }
        return recordToTranslate;
    }

    /*
    * @Method       : updateApprovedFileTranslations.
    * @Description  : To update all the approved translated files to their respective parent fields.
    * @Invoke       : From ADDS4TranslationTaskTiggerHandler class.
    * @Return       : N/A.
    * @Params       : Set<String> translationTaskIds.
    */
    @Future
    public static void updateApprovedFileTranslations(Set<String> translationTaskIds) {
        TicketUtil.addTrace('ADDTranslations.updateApprovedFileTranslations');
        TicketUpdateUtility.executeFlag = false;
        Map<String, String> customAttIds = new Map<String, String>();
        List<Attachment> attachments = new List<Attachment>();
        Map<String, Attachment__c> customAttMap = new Map<String, Attachment__c>();
        //following for loop gets all  translation tasks attachments and creates the new custom attachments.
        for (Translation_Task__c translationTask : [SELECT Id,Email_Attachments__c, (SELECT Id, Name FROM Attachments ORDER BY CreatedDate ASC) FROM Translation_Task__c
            WHERE Id IN :translationTaskIds AND
            RecordType.Name = :AspenConstants.RECTYPE_TRANSTASK_ATTACH
        ]) {
            for (Attachment att : translationTask.Attachments) {
                if (att.Name.contains('-')) {
                    Set<String> setTempAttachments = (Set<String>)System.JSON.deserialize(translationTask.Email_Attachments__c, Set<String>.class);
                    if (setTempAttachments.size() > 0 && setTempAttachments.contains(att.Name.substringBefore('-').trim())) {
                        customAttIds.put(att.Name.substringBefore('-'), att.Id);
                    }
                }
            }
        }
        if (customAttIds.size() > 0) {
            for(Attachment__c att : [SELECT Id, Name, Attachment_Title__c, Attachment_Description__c, Last_Modified__c,
                    Attachment_Status__c, Ticket__c, Deletion_Justification__c, Send_to_CMSNext__c,
                    Return__c, Attachment_Type__c, Delete_Flag__c, Customer_Response__c,
                    Customer_Response_Master__c, Investigation_Evaluation__c, Evaluation_Investigation_Task__c,
                    Assessment__c, Medical_Evaluation_Task__c, EMDR__c, MEDDEV__c, Regulatory_Task__c,
                    Tracking_Trending_Review_Task__c,Translation_Task__c,Translation_Task__r.Parent_Ticket__c,
                    Parent_Id__c, Registration_Ticket_Number__c, UNC_Path__c,
                    Division__c, CMPL123Rule_Key_Value__c, Registartion_Attachment__c, Ticket_Number__c,
                    Attachment_Id__c, Key_List__c, Related_Ticket_Id__c FROM Attachment__c WHERE Id IN: customAttIds.keySet()]) {

                Attachment__c customAtt = att.clone();
                customAtt.Ticket__c = att.Translation_Task__r.Parent_Ticket__c;
                customAtt.Name = att.Name + '-Translated';
                customAttMap.put(att.Id, customAtt);
            }
            if (customAttMap.keySet().size() > 0) {
                ADDCustomAttachmentTriggerHandler.executeAttachmentFlag = false;
                insert customAttMap.values();
                //following block is used to create a standard attachments whose parent id is cstom attachment which are created recently.
                for (Attachment attach : [SELECT Id, ParentId, Name, ContentType, Body, Description
                FROM Attachment WHERE Id IN: customAttIds.values()]) {
                    if(attach.Name.contains('-') && customAttMap.get(attach.Name.substringBefore('-')) != null) {
                        Attachment newAtt = attach;
                        newAtt.Id = null;
                        newAtt.ParentId = customAttMap.get(attach.Name.substringBefore('-')).Id;
                        attachments.add(newAtt);
                    }
                }
                if (attachments.size() > 0) {
                    insert attachments;
                    delete [SELECT Id FROM Attachment WHERE ParentId IN: translationTaskIds];
                }
                ADDCustomAttachmentTriggerHandler.executeAttachmentFlag = true;
            }
        }
    }

    /*
    * @Method       : setDefaults.
    * @Description  : To construct the default map of Countries.
    * @Invoke       : From ADDTranslations class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void setDefaults() {
        TicketUtil.addTrace('ADDTranslations.setDefaults');
        if (countryNameWithId == null || countryNameWithId.keySet().size() == 0) {
            countryNameWithId = new Map<String, String>();

            for (Country__c country : [SELECT Id, Division__c, Name FROM Country__c
                WHERE Translations_Required_flag__c = TRUE]) {
                countryNameWithId.put(country.Name + '-' + country.Division__c, country.Id);
            }
        }

        if (recordTypeNameWithIdMap == null || recordTypeNameWithIdMap.keySet().size() == 0) {
            recordTypeNameWithIdMap = ADDUtil.getRecordTypeMap(SOBJ_TICKET);
        }

        if (objectTFMap == null) {
            objectTFMap = new Map<String, List<Translation_Fields__mdt>>();
        }

        if (objectTFMap.size() == 0) {
            String objName = '';
            for (Translation_Fields__mdt field : [SELECT Id, DeveloperName, MasterLabel,
                    Translated_Field_Label__c, Translated_Field_Name_API__c,
                    Object_API__c, Related_Complaint_API__c
            FROM Translation_Fields__mdt
            ORDER BY Object_API__c]) {
                if (objName.equalsIgnoreCase(field.Object_API__c)) {
                    objectTFMap.get(objName).add(field);
                } else {
                    objName = field.Object_API__c;
                    objectTFMap.put(objName, new List<Translation_Fields__mdt>{field});
                }
            }
        }
    }
}