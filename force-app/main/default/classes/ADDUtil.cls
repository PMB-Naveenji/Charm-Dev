/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : ADDUtil.
 * @Why   : Public class which has all the util methods, which can be referenced anywhere with in the organization.
 * @When  : 23-MAR-2017.
 * @Where : From ADDDefineSearchController class, ADDInvestigationHandler class, ADDS5DynamicSearchController class, ADDSearchController class,
 *          ADDTranslations class, ADDTrendItemHandler class, ADDTrendItemMaintainanceReqHandler class, ComplaintTriggerHandler class,
 *          SyncSubmissionsFromMedEval class, UpdateSearchResultRecords class, ADDActionTask class, ADDHazardAssessmentTriggerHandler class,
 *          ADDInvestigationTaskTriggerHandler class, ADDMedEvalTaskTriggerHandler class, ADDRegulatoryAssessmentTriggerHandler class,
 *          ADDRegulatoryTaskTriggerHandler class, ADDReturnTriggerHandler class, ADDS4RiskManagementTriggerHandler class, QuestionnaireTriggerHandler class.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID                                       Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                   23-MAR-2017            Work ID / Case ID                                      Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    15-JUN-2020            Code Audit                                            Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * vkaih                    18-AUG-2020            Code Audit                                            Updated class comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Juneid                   22 June 2021           MIR Devlopment                                         Added Logic for MIR fields for Search 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             23-MAY-2023            CHaRM R3.1                                            Made formatDateStandardized
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vinay Kaipra Puthneveettil  23-May-2023         CHarm R3.1 (IPDR 506)                                 Added new method 'getCurrentDateInGMT'
                                                                                                         to return current date in GMT
 * --------------------------------------------------------------------------------------------------------------------------------------------
 * Dinesh Kumar             22-June-2023           CHARM R3.1 (IPDR 506)                                 Added new method 'getOriginalTicketCloseDateEffectiveFrom' to get the value from the custom
                                                                                                         Setting "CHaRM_Misc_Settings__c"
 * --------------------------------------------------------------------------------------------------------------------------------------------
 */

public with sharing class ADDUtil{
    /*
    * @Method       : generateNotification.
    * @Description  : To create single email message based on the provided inputs.
    * @Invoke       : From ComplaintTriggerHandler class.
    * @Return       : Messaging.SingleEmailMessage mail.
    * @Params       : String emailBody, String targetObjectId, String subject, List<String> ccEmails.
    */
    public static Messaging.SingleEmailMessage generateNotification(String emailBody, String targetObjectId, String subject,
        List<String> ccEmails){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(targetObjectId);
        mail.setSaveAsActivity(false);
        mail.setSubject(subject);
        mail.setHtmlBody(emailBody);
        if(ccEmails.size() > 0){
            mail.setCcAddresses(ccEmails);
        }
        return mail;
    }

    /*
    * @Method       : processAutomatedHistoryRecord.
    * @Description  : To construct an automated history record based on the step as parameters.
    * @Invoke       : N/A.
    * @Return       : CMPL123__WF_History__c autoPromotedHistory.
    * @Params       : String parentId, CMPL123__WF_Step__c WFStep.
    */
    public static CMPL123__WF_History__c processAutomatedHistoryRecord(String parentId, CMPL123__WF_Step__c WFStep){
        CMPL123__WF_History__c autoPromotedHistory = new CMPL123__WF_History__c(
            CMPL123__Related_Id__c = parentId,
            CMPL123__Workflow_Step__c = WFStep.Id,
            CMPL123__Action__c = WFStep.CMPL123__Action__r.Name,
            CMPL123__ESign_Applied__c = false, //WFStep.CMPL123__Action__r.CMPL123__Is_ESign_Required__c,
            CMPL123__Comment__c = 'Applied through task update',
            CMPL123__Status__c = WFStep.CMPL123__End_Status__r.Name,
            CMPL123__Change_Summary__c= 'Updated Status From '+WFStep.CMPL123__Start_Status__r.Name+' to '+ WFStep.CMPL123__End_Status__r.Name
        );
        return autoPromotedHistory;
    }

    /*
    * @Method       : getRecordTypeMap.
    * @Description  : To construct a Map of Record Types.
    * @Invoke       : From ADDInvestigationHandler class, ADDTranslations class, ADDTrendItemHandler class,
    *                 ADDTrendItemMaintainanceReqHandler class, SyncSubmissionsFromMedEval class.
    * @Return       : Map<String, String> recordTypeMap.
    * @Params       : String objectName.
    */
    public static Map<String, String> getRecordTypeMap(String objectName){
        TicketUtil.addTrace('ADDUtil.getRecordTypeMap');
        Map<String, String> recordTypeMap = new Map<String, String>();
        for(Schema.RecordTypeInfo rt :
            Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfos()) {
            recordTypeMap.put(rt.getName(), rt.getRecordTypeId());
            recordTypeMap.put(rt.getRecordTypeId(), rt.getName());
        }

        return recordTypeMap;
    }

    /*
    * @Method       : getObjectDetails.
    * @Description  : To construct a Map with object details.
    * @Invoke       : From ADDDefineSearchController class, ADDSearchController class.
    * @Return       : List<ADDSearchController.ObjectDetail> objectDetails.
    * @Params       : N/A.
    */
    public static List<ADDSearchController.ObjectDetail> getObjectDetails(){
        List<ADDSearchController.ObjectDetail> objectDetails =
            new List<ADDSearchController.ObjectDetail>();
        Map<String, String> objectAPILabelMap = new Map<String, String>();

        Schema.DescribeSObjectResult res = CMPL123CME__Complaint__c.SObjectType.getDescribe();
        List<String> objectAPIs = new List<String>{'CMPL123CME__Complaint__c'};
        for (Schema.ChildRelationship cr : res.getChildRelationships()) {
            if(!ADDStaticResources.EXCLUDEOBJECTSET.contains(String.valueOf(cr.getChildSObject()))) {
                objectAPIs.add(String.valueOf(cr.getChildSObject()));
            }
        }
        for(Schema.DescribeSObjectResult result : Schema.describeSObjects(objectAPIs)) {
            objectAPILabelMap.put(String.valueOf(result.getName()),
            String.valueOf(result.getLabel()));
        }
        objectDetails.add(
            new ADDSearchController.ObjectDetail(
                'CMPL123CME__Complaint__c',
                objectAPILabelMap.get('CMPL123CME__Complaint__c'),
                null,
                null
            )
        );
        for (Schema.ChildRelationship cr : res.getChildRelationships()) {

            if(String.valueOf(cr.getChildSObject()).contains('__c')
                && !ADDStaticResources.EXCLUDEOBJECTSET.contains(String.valueOf(cr.getChildSObject()))){

                objectDetails.add(
                    new ADDSearchController.ObjectDetail(
                        String.valueOf(cr.getChildSObject()),
                        objectAPILabelMap.get(String.valueOf(cr.getChildSObject())),
                        String.valueOf(cr.getField()),
                        String.valueOf(cr.getRelationshipName())
                    )
                );
            }
        }
        return objectDetails;
    }

    /*
    * @Method       : processTicketSearchResults.
    * @Description  : To calculate the total number of eMDRs, MDIs and submission information for the existing ticket search results.
    * @Invoke       : From UpdateSearchResultRecords class.
    * @Return       : N/A.
    * @Params       : List<ID> ticketSearchResultIdList.
    */
    @future
    public static void processTicketSearchResults(List<ID> ticketSearchResultIdList){
        Set<ID> ticketIdSet = new Set<ID>();
        List<Ticket_Search_Result__c> ticketSearchResultsList = new List<Ticket_Search_Result__c>();
        Map<ID,Ticket_Search_Result__c> ticketIdAndTicketSearchResultMap = new Map<ID,Ticket_Search_Result__c>();
        //@Juneid 22 June 2021, Added MIR field for Search
        for(Ticket_Search_Result__c ticketSearchResult : [SELECT Id,Ticket__c,Total_Number_of_eMDR__c,
                                                          Total_Number_of_MDI__c,Total_Number_of_EU_MIR__c,Submission_Information__c
                                                          FROM Ticket_Search_Result__c
                                                          WHERE ID IN : ticketSearchResultIdList]){
            ticketIdSet.add(ticketSearchResult.Ticket__c);
            ticketIdAndTicketSearchResultMap.put(ticketSearchResult.Ticket__c,ticketSearchResult);
        }
        //@Juneid 22 June 2021, Added a EUIR in Query
        for(CMPL123CME__Complaint__c ticketData : [SELECT Id,
                                                   (SELECT CMPL123CME__Type_of_Report__c,CMPL123_WF_Status__c FROM CMPL123CME__MEDDEV__r),
                                                   (SELECT RecordType.Name,CMPL123CME__CMPL123_WF_Status__c,Classification__c FROM CMPL123CME__EMDR__r),
                                                   (SELECT CMPL123CME__Type_of_Report__c,CMPL123_WF_Status__c FROM CMPL123CME__EU_MIR__r)
                                                    FROM CMPL123CME__Complaint__c WHERE ID IN : ticketIdSet]){

            if(ticketIdAndTicketSearchResultMap.size() > 0 &&
                ticketIdAndTicketSearchResultMap.containsKey(ticketData.Id)){
                    Ticket_Search_Result__c ticketSearchResultData  = ticketIdAndTicketSearchResultMap.get(ticketData.Id);
                    ticketSearchResultData.Total_Number_of_MDI__c = ticketData.CMPL123CME__MEDDEV__r.size();
                    ticketSearchResultData.Total_Number_of_eMDR__c = ticketData.CMPL123CME__EMDR__r.size();
                      //@Juneid 22 June 2021, Added MIR for Search
                    ticketSearchResultData.Total_Number_of_EU_MIR__c = ticketData.CMPL123CME__EU_MIR__r.size();
                    ticketSearchResultData.Submission_Information__c = '';
                    for(CMPL123CME__MEDDEV__c meddevRecord : ticketData.CMPL123CME__MEDDEV__r){
                        ticketSearchResultData.Submission_Information__c +=
                            (meddevRecord.CMPL123CME__Type_of_Report__c != null ? meddevRecord.CMPL123CME__Type_of_Report__c+'~' : '') +
                            +'MDI'+
                            '~'+meddevRecord.CMPL123_WF_Status__c+'\n';

                    }
                    for(CMPL123CME__EMDR__c emdrRecord : ticketData.CMPL123CME__EMDR__r){
                        ticketSearchResultData.Submission_Information__c += emdrRecord.RecordType.Name +'~'+'eMDR'+'~'+
                            emdrRecord.CMPL123CME__CMPL123_WF_Status__c+
                            (emdrRecord.Classification__c != null ? '~'+ emdrRecord.Classification__c : '')+'\n';
                    }
                   //@Juneid 22 June 2021, Added for EUMIR Tciket Search
        for(CMPL123CME__EU_MIR__c euMirRecord : ticketData.CMPL123CME__EU_MIR__r){
            ticketSearchResultData.Submission_Information__c +=
                (CMPL123CME__EU_MIR__c.CMPL123CME__Type_of_Report__c != null ? CMPL123CME__EU_MIR__c.CMPL123CME__Type_of_Report__c+'~' : '') +
                +'EUMIR'+
                '~'+CMPL123CME__EU_MIR__c.CMPL123_WF_Status__c+'\n';

        }
                    ticketSearchResultsList.add(ticketSearchResultData);
            }

        }

        if(ticketSearchResultsList.size() > 0){
            update ticketSearchResultsList;
        }

    }

    /*
    * @Method       : fetchReopenWorkflowHistory.
    * @Description  : To query the last applied reopen workflow history record comments.
    * @Invoke       : From trigger handlers of various objects which have reopen action in workflow life cycle.
    * @Return       : String reopenRationale.
    * @Params       : String recordId.
    */
    public static String fetchReopenWorkflowHistory(String recordId){
        String reopenRationale;
        try{
        CMPL123__WF_History__c wf = [SELECT Id, CMPL123__Comment__c FROM CMPL123__WF_History__c
                                     WHERE CMPL123__Related_Id__c =: recordId AND CMPL123__Comment__c != null
                                     AND CMPL123__Action__c LIKE '%Reopen%' ORDER BY CreatedDate desc LIMIT 1];
        reopenRationale = wf.CMPL123__Comment__c;
        }catch(QueryException qe){
            System.debug('Query exception while fetching reopen record: '+qe.getMessage());
        }
        return reopenRationale;
    }

    /**
     * Formats a passed date to match Abbott's standardized notation.
     * 
     * This format is dd-MON-yyyy
     * @author Larry Resnik
     * @date 23-MAY-2023
     */
    public static String formatDateStandardized(Date theDate) {
        return String.format('{0}-{1}-{2}', new Object[]{
            String.valueOf(theDate.day()).leftPad(2, '0'),
            AspenConstants.MONTH_INDEX_TO_SHORT_NAME.get(theDate.month()),
            theDate.year()
        });
    }

    /**
     * Formats a passed date to match JavaScript logic in TicketTranslation.page
     * 
     * This format is MON-d-yyyy.
     * @author Larry Resnik
     * @date 23-MAY-2023
     */
    public static String formatDateTicketTranslation(Date theDate) {
        return String.format('{0}-{1}-{2}', new Object[]{
            AspenConstants.MONTH_INDEX_TO_SHORT_NAME.get(theDate.month()),
            theDate.day(),
            theDate.year()
        });
    }

    /**
     * Method to return Current Date in GMT
     * Added for IPDR 506
     *
     * @author Vinay Kaipra Puthneveettil
     * @date 08-JUN-2023
     */
    public static Date getCurrentDateInGMT() {
        return System.now().dateGmt();
    }
    
    /** 
     * Method to return "Original Ticket Close date effective from" from 'CHARM Misc Custom setting'
     * Original Ticket Close date effective from will be set to Charm 3.1 release date
     * Tickets that are created after Charm 3.1 release will have "Original Ticket Close date" field populated
     * Added for IPDR 506
     *
     * @author Dinesh Kumar
     * @date 22-JUN-2023
     */    
    public static DateTime getOriginalTicketCloseDateEffectiveFrom() {
        return CHaRM_Misc_Settings__c.getOrgDefaults().Original_Ticket_Close_Date_EffectiveFrom__c;
	}
}