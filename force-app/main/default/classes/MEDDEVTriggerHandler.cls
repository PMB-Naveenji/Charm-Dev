/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : MEDDEVTriggerHandler.
* @Why   : Public class to manage all the custom coding invoked on the CMPL123CME__MEDDEV__c object.
* @When  : 23-MAR-2017.
* @Where : From MEDDEVTriggerHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            N/A                         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    19-MAR-2020            CHARM-2113                  Modified.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    13-APR-2020            Defect #70 fix              Modified.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                  Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    05-JUN-2020            #123/CHARM-2729             Added updateTicketLastModifiedDate method.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    10-JUN-2020            Defect #95/CHARM-2517       Changed from 'CMPL123CME__Manufacturer_Country__c'
*                                                                             to 'CMPL123CME__ManufacturerCountry__c'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                  Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    08-JUL-2020            Code Audit                  Updated defect #95 references.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    27-OCT-2020            HC #100/CHARM-3518          Added checkEditableOnPendingStatus method.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    20-NOV-2020            HC #72/CHARM-3536           Added validation upon 'Follow Up Required' action.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue           Added 'executeLogicFromWFRules()' method to move logic from
*                                                                               Workflow Rules with Field Updates on MEDDEV to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class MEDDEVTriggerHandler {
    public static Boolean isFollowUpsCreated = false;
    // Def HC #100/CHARM-3518 fix: added isEditAccessOnPendingChecked flag
    public static Boolean isEditAccessOnPendingChecked = false;

    /**
    * @Method       : beforeEventHandler
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public static void beforeEventHandler() {
        List<CMPL123CME__MEDDEV__c> newMedDevs = (List<CMPL123CME__MEDDEV__c>)Trigger.New;
        Map<Id,CMPL123CME__MEDDEV__c> oldMedDevMap = (Map<Id,CMPL123CME__MEDDEV__c>)Trigger.oldMap;
        Map<Id,CMPL123CME__MEDDEV__c> newMedDevMap = (Map<Id,CMPL123CME__MEDDEV__c>)Trigger.newMap;

        Set<String> ticketIdSet = new Set<String>();
        Map<String,Contact__c> ticketWithContactMap = new Map<String,Contact__c>();
        Map<String,CMPL123CME__Complaint__c> ticketWithCustomerMap = new Map<String,CMPL123CME__Complaint__c>();
        Set<Id> setMedEvalIds = new Set<Id>();
        Map<Id, CMPL123CME__Questionnaire__c> mapMedEvals = new Map<Id, CMPL123CME__Questionnaire__c>();
        // Def HC #72/CHARM-3536: added updatedToPendingFollowUpMDIs and setFollowUpIds sets
        Set<String> updatedToPendingFollowUpMDIs = new Set<String>();
        Set<Id> setFollowUpIds = new Set<Id>();

        //Added - W-000204 - Start
        if(Trigger.isUpdate){
            checkRegulatoryTaskBeforeWaive(newMedDevMap,oldMedDevMap);
        }
        //Added - W-000204 - Start

        //Added - #1520 Critical Defect (Fill in Manufacturer Section Fields)
        if (Trigger.isInsert && Trigger.isBefore) {
            Set<Id> registeredSiteIds = new Set<Id>();
            for (CMPL123CME__MEDDEV__c meddev : newMedDevs) {
                registeredSiteIds.add(meddev.Registered_Site__c);
            }

            List<CMPL123CME__Registered_Site__c> registeredSites = [
                SELECT Manufacturer_E_mail__c, Manufacturer_Address__c, Manufacturer_City__c, Manufacturer_Contact__c,
                    Manufacturer_Country__c, Manufacturer_Fax__c, Manufacturer_Name__c, Manufacturer_Phone__c, Manufacturer_Postcode__c
                FROM CMPL123CME__Registered_Site__c
                WHERE Id IN :registeredSiteIds
                LIMIT 50000
            ];

            for (CMPL123CME__MEDDEV__c meddev : newMedDevs) {
                for (CMPL123CME__Registered_Site__c registeredSite : registeredSites) {
                    if (meddev.Registered_Site__c == registeredSite.Id) {
                        meddev.CMPL123CME__Manufacturer_Email__c = registeredSite.Manufacturer_E_mail__c;
                        meddev.CMPL123CME__Manufacturer_Phone__c = registeredSite.Manufacturer_Phone__c;
                        meddev.CMPL123CME__Manufacturer_Name__c = registeredSite.Manufacturer_Name__c;
                        meddev.CMPL123CME__Manufacturer_Fax__c = registeredSite.Manufacturer_Fax__c;

                        //  Defect #95/CHARM-2517 fix start
                        meddev.CMPL123CME__ManufacturerCountry__c = registeredSite.Manufacturer_Country__c;
                        //  Defect #95/CHARM-2517 fix end

                        meddev.CMPL123CME__Manufacturer_Contact__c = registeredSite.Manufacturer_Contact__c;
                        meddev.CMPL123CME__Manufacturer_City__c = registeredSite.Manufacturer_City__c;
                        meddev.CMPL123CME__Manufacturer_Address__c = registeredSite.Manufacturer_Address__c;
                        meddev.CMPL123CME__Manufacturer_Postal_code__c = registeredSite.Manufacturer_Postcode__c;
                    }
                }
            }
        }

        for(CMPL123CME__MEDDEV__c meddev : newMedDevs){
            CMPL123CME__MEDDEV__c oldMeddev = Trigger.isUpdate && oldMedDevMap != null ?
                oldMedDevMap.get(meddev.Id) : null;
            if(meddev.Medical_Evaluation__c != null){
                setMedEvalIds.add(meddev.Medical_Evaluation__c);
            }

            //Added - W-000192 clear task key value - Start
            if(meddev.CMPL123_WF_Action__c == 'Reject' && oldMeddev != null && meddev.CMPL123_WF_Action__c != oldMeddev.CMPL123_WF_Action__c){
                meddev.CMPL123Task_Key_Value__c = '';
            }
            //Added - W-000192 clear task key value - Start

            // Def HC #72/CHARM-3536
            if (meddev.CMPL123_WF_Status__c == 'Pending Follow Up Creation' && oldMeddev != null && oldMeddev.CMPL123_WF_Status__c == 'Closed-Done') {
                updatedToPendingFollowUpMDIs.add(meddev.Id);
                if (meddev.Initial_MDI__c != null) {
                    updatedToPendingFollowUpMDIs.add(meddev.Initial_MDI__c);
                    setFollowUpIds.add(meddev.Id);
                }
            }

            if(meddev.CMPL123CME__Complaint__c != null && oldMeddev == null
               || (oldMeddev != null && meddev.CMPL123CME__Complaint__c != oldMeddev.CMPL123CME__Complaint__c)){

                   ticketIdSet.add(meddev.CMPL123CME__Complaint__c);
               }
        }

        // Def HC #72/CHARM-3536 fix: validation for existing opened supplementals upon 'Follow Up Required'
        if (updatedToPendingFollowUpMDIs.size() > 0) {
            for (CMPL123CME__MEDDEV__c meddevRecord : [SELECT Id, (SELECT Id FROM MDIs__r
                                                                    WHERE CMPL123_WF_Status__c NOT IN ('Closed-Done', 'Closed-Voided', 'Closed - Waived')
                                                                        AND Id NOT IN: setFollowUpIds)
                                                        FROM CMPL123CME__MEDDEV__c WHERE Id =: updatedToPendingFollowUpMDIs]) {
                if(meddevRecord.MDIs__r.size() > 0) {
                    newMedDevs[0].addError(Label.MDI_Prevent_creating_Follow_up_MDI_with_another_having_not_closed_status);
                }
            }
        }
        if(ticketIdSet.size() > 0){
            //Added - W-000130 query fields
            for(CMPL123CME__Complaint__c ticket : [SELECT Id,CMPL123CME__Customer__r.Name,CMPL123CME__Customer__r.City__c, CMPL123CME__Customer__r.Country__c,CMPL123CME__Customer__r.Zip_Postal_Code__c, CMPL123CME__Customer__r.Customer_City_Translated__c,CMPL123CME__Customer__r.Customer_Name_Translated__c,
                                                   CMPL123CME__Customer__r.Contact_Address_Line_1__c,CMPL123CME__Customer__r.Contact_Address_Line_2__c,CMPL123CME__Customer__r.Customer_Address_Line_1_Translated__c, CMPL123CME__Customer__r.Customer_Address_Line_2_Translated__c,(SELECT Id, Name, Contact_Email__c,
                                                                                                                                                                                                                                                                                     Contact_Fax__c, Customer_Name__c,Customer_Name__r.Name, Contact_Phone_Number__c, Primary__c,
                                                                                                                                                                                                                                                                                     Name__c,Contact_Name_Translated__c,Customer_Name_Translated__c,
                                                                                                                                                                                                                                                                                     pRE__c FROM Related_Contact__r WHERE (pRE__c = true OR Primary__c = true) AND External_ID__c != null ORDER BY External_ID__c NULLS LAST)
                                                   FROM CMPL123CME__Complaint__c WHERE Id IN :ticketIdSet]){

                                                       ticketWithCustomerMap.put(ticket.Id,ticket);

                                                       if(ticket.Related_Contact__r.size() > 0) {
                                                           Contact__c pREContact;
                                                           Contact__c primaryContact;

                                                           for(Contact__c contactRecord : ticket.Related_Contact__r){
                                                               if(pREContact == null && contactRecord.pRE__c){
                                                                   pREContact = contactRecord;
                                                               }else if(primaryContact == null && contactRecord.Primary__c){
                                                                   primaryContact = contactRecord;
                                                               }
                                                           }
                                                           if(pREContact != null || primaryContact != null){
                                                               if(pREContact != null){
                                                                   ticketWithContactMap.put(ticket.Id, pREContact);
                                                               }else{
                                                                   ticketWithContactMap.put(ticket.Id, primaryContact);
                                                               }
                                                           }
                                                       }
                                                   }
        }

        if(setMedEvalIds.size() > 0){
            mapMedEvals = new Map<Id, CMPL123CME__Questionnaire__c>([SELECT Id,
                                                                     Final_Mfg_Analysis_New__c , Initial_Follow_Up_Mfg_Analysis_New__c
                                                                     FROM CMPL123CME__Questionnaire__c WHERE Id =: setMedEvalIds]);
        }

        for(CMPL123CME__MEDDEV__c meddev : newMedDevs) {
            CMPL123CME__MEDDEV__c oldMeddev = Trigger.isUpdate && oldMedDevMap != null ?
                oldMedDevMap.get(meddev.Id) : null;
            //Added W-000193
            if(meddev.Medical_Evaluation__c != null && mapMedEvals != null && !mapMedEvals.isEmpty()
               && mapMedEvals.containsKey(meddev.Medical_Evaluation__c) && oldMeddev != null && meddev.CMPL123CME__Type_of_Report__c != oldMeddev.CMPL123CME__Type_of_Report__c) {
                   if(meddev.CMPL123CME__Type_of_Report__c == 'Initial report' || meddev.CMPL123CME__Type_of_Report__c == 'Follow-up report'){
                       meddev.CMPL123CME__Manufacturer_Preliminary_Analysis__c  = mapMedEvals.get(meddev.Medical_Evaluation__c).Initial_Follow_Up_Mfg_Analysis_New__c != null ? mapMedEvals.get(meddev.Medical_Evaluation__c).Initial_Follow_Up_Mfg_Analysis_New__c : meddev.CMPL123CME__Manufacturer_Preliminary_Analysis__c ;
                       meddev.CMPL123CME__Manufacturer_Device_Analysis_Results__c = '';
                   }
                   if(meddev.CMPL123CME__Type_of_Report__c == 'Combined initial and final report' || meddev.CMPL123CME__Type_of_Report__c == 'Final report'){
                       meddev.CMPL123CME__Manufacturer_Device_Analysis_Results__c = mapMedEvals.get(meddev.Medical_Evaluation__c).Final_Mfg_Analysis_New__c != null ? mapMedEvals.get(meddev.Medical_Evaluation__c).Final_Mfg_Analysis_New__c : meddev.CMPL123CME__Manufacturer_Device_Analysis_Results__c;
                       meddev.CMPL123CME__Manufacturer_Preliminary_Analysis__c = '';
                   }
               }

            //Added W-000179 - meddev.CMPL123CME__Type_of_Report__c != 'Follow-up report'
            if((meddev.CMPL123CME__Complaint__c != null && oldMeddev == null && meddev.CMPL123CME__Type_of_Report__c != 'Follow-up report')
               || (oldMeddev != null && meddev.CMPL123CME__Complaint__c != oldMeddev.CMPL123CME__Complaint__c)){

                   if(ticketWithContactMap.get(meddev.CMPL123CME__Complaint__c) != null){
                       Contact__c contactRecord = ticketWithContactMap.get(meddev.CMPL123CME__Complaint__c);
                       CMPL123CME__Complaint__c customerRecord = ticketWithCustomerMap.get(meddev.CMPL123CME__Complaint__c);

                       //Added - W-000130
                       meddev.CMPL123CME__HealthCare_City__c = customerRecord.CMPL123CME__Customer__r.Customer_City_Translated__c != null ? customerRecord.CMPL123CME__Customer__r.Customer_City_Translated__c : customerRecord.CMPL123CME__Customer__r.City__c;
                       meddev.CMPL123CME__Contact_Person_in_Facility__c = contactRecord.Contact_Name_Translated__c != null ? contactRecord.Contact_Name_Translated__c : contactRecord.Name__c;
                       meddev.CMPL123CME__HealthcareCountry__c = customerRecord.CMPL123CME__Customer__r.Country__c;
                       meddev.CMPL123CME__HealthCare_Email__c = contactRecord.Contact_Email__c;
                       meddev.CMPL123CME__HealthCare_Fax__c = contactRecord.Contact_Fax__c;
                       //Added - W-000350
                       meddev.CMPL123CME__Name_of_Healthcare_Facility__c = contactRecord.Customer_Name_Translated__c != null ? contactRecord.Customer_Name_Translated__c : contactRecord.Customer_Name__r.Name;

                       //Added - W-000350
                       meddev.CMPL123CME__HealthCare_Address__c = customerRecord.CMPL123CME__Customer__r.Customer_Address_Line_1_Translated__c != null && customerRecord.CMPL123CME__Customer__r.Customer_Address_Line_2_Translated__c != null  ? (customerRecord.CMPL123CME__Customer__r.Customer_Address_Line_1_Translated__c+'\n'+customerRecord.CMPL123CME__Customer__r.Customer_Address_Line_2_Translated__c ): (customerRecord.CMPL123CME__Customer__r.Contact_Address_Line_1__c+'\n'+customerRecord.CMPL123CME__Customer__r.Contact_Address_Line_2__c);

                           meddev.CMPL123CME__HealthCare_Phone__c = contactRecord.Contact_Phone_Number__c;
                       meddev.CMPL123CME__HealthCare_Postal_Code__c = customerRecord.CMPL123CME__Customer__r.Zip_Postal_Code__c;
                   }
               }
        }
        //defect #916
        if(Trigger.isInsert || Trigger.isUpdate){
            setDefaultsOnCreation(newMedDevs);
            setDueDateOnMDI(newMedDevs, oldMedDevMap);
        }
    }

    /**
    * @Method       : afterEventHandler
    * @Invoke       : Events from TriggerHandler after EventHandler
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public static void afterEventHandler() {
        //Added - W-000633
        Set<Id> mdiSet = new Set<Id>();
        Set<Id> setFollowUpIds = new Set<Id>();
        Set<Id> nonEligibleMdiSet = new Set<Id>();
        Set<Id> followUpToCreate = new Set<Id>();
        List<CMPL123CME__MEDDEV__c> newMedDevs = (List<CMPL123CME__MEDDEV__c>)Trigger.New;
        Map<Id,CMPL123CME__MEDDEV__c> oldMedDevMap = (Map<Id,CMPL123CME__MEDDEV__c>)Trigger.oldMap;
        List<CMPL123CME__MEDDEV__c> followUpList = new List<CMPL123CME__MEDDEV__c>();

        for (CMPL123CME__MEDDEV__c meddev : newMedDevs) {
            CMPL123CME__MEDDEV__c oldMeddev = Trigger.isUpdate && oldMedDevMap != null ?
                    oldMedDevMap.get(meddev.Id) : null;

            if (meddev.Follow_Up_Required__c == 'Yes' && (meddev.CMPL123_WF_Status__c == 'Pending Follow Up Creation'
                    || meddev.CMPL123_WF_Status__c == 'Pending Final Review') && (oldMeddev == null ||
                    (oldMeddev != null && meddev.Follow_Up_Required__c != oldMeddev.Follow_Up_Required__c))) {
                mdiSet.add(meddev.Id);
                if (meddev.Initial_MDI__c != null) {
                    mdiSet.add(meddev.Initial_MDI__c);
                    setFollowUpIds.add(meddev.Id);
                }
            }
            // FRS-1540-03 implementation
            if (!isFollowUpsCreated && meddev.Follow_Up_Required__c == 'Yes' && meddev.CMPL123_WF_Status__c == 'Closed-Done' &&
                    (oldMeddev != null && meddev.CMPL123_WF_Status__c != oldMeddev.CMPL123_WF_Status__c)) {
                followUpToCreate.add(meddev.Id);
            }
        }

        if(mdiSet.size() > 0){
            for (CMPL123CME__MEDDEV__c meddevRecord : [SELECT Id, (SELECT Id FROM MDIs__r WHERE CMPL123_WF_Status__c != 'Closed-Done'
            AND CMPL123_WF_Status__c != 'Closed-Voided' AND CMPL123_WF_Status__c != 'Closed - Waived' AND Id NOT
                    IN: setFollowUpIds LIMIT 1) FROM CMPL123CME__MEDDEV__c WHERE Id =: mdiSet]) {
                if(meddevRecord.MDIs__r.size() == 1)
                    nonEligibleMdiSet.add(meddevRecord.Id);
            }

            if (nonEligibleMdiSet.size() > 0) {
                newMedDevs[0].addError(Label.MDI_Prevent_creating_Follow_up_MDI_with_another_having_not_closed_status, false);
            }
        }

        if (followUpToCreate.size() > 0 ) {
            for (CMPL123CME__MEDDEV__c objMeddev : newMedDevs) {

                if (followUpToCreate.contains(objMeddev.Id)) {
                    String parentMDIId = objMeddev.Initial_MDI__c == null ? objMeddev.Id : objMeddev.Initial_MDI__c;
                    system.debug('parentMDIId-->'+parentMDIId);

                    CMPL123CME__MEDDEV__c copiedMeddev = new CMPL123CME__MEDDEV__c(Initial_MDI__c = parentMDIId,
                            CMPL123CME__Type_of_Report__c = 'Follow-up report');

                    copiedMeddev.put('Committed_Next_Report_date__c', objMeddev.CMPL123CME__Expected_Date_of_Next_Report__c);
                    for (Schema.FieldSetMember f :
                            SObjectType.CMPL123CME__MEDDEV__c.FieldSets.Follow_up_auto_populate.getFields()){
                        copiedMeddev.put(f.getFieldPath(), objMeddev.get(f.getFieldPath()));
                    }
                    followUpList.add(copiedMeddev);
                }
            }
            if (followUpList.size() > 0) {
                insert followUpList;
                system.debug('followUpList--->'+followUpList);
                isFollowUpsCreated = true;
            }
        }
    }

    /**
    * @Method       : checkRegulatoryTaskBeforeWaive
    * @Invoke       : To handle check Regulatory Task Be fore Waive
    * @Description  : W-000204 - 767 / (MDI) Add a validation rule that will not
    allow user to waive MDIs if the Vigilance Contact has answered the question
    * @Return       : N/A
    * @Params       : Map<Id,CMPL123CME__MEDDEV__c> mapMeddevsNew, Map<Id,CMPL123CME__MEDDEV__c> mapMeddevsOld
    **/
    private static void checkRegulatoryTaskBeforeWaive(Map<Id,CMPL123CME__MEDDEV__c> mapMeddevsNew, Map<Id,CMPL123CME__MEDDEV__c> mapMeddevsOld){
        Set<Id> setMedDevIds = New Set<Id>();
        for(CMPL123CME__MEDDEV__c objMEDDEV : mapMeddevsNew.values()){
            if(objMEDDEV.CMPL123_WF_Action__c == 'Waive' && mapMeddevsOld.get(objMEDDEV.Id).CMPL123_WF_Status__c == 'Pending Final Review'){
                setMedDevIds.add(objMEDDEV.Id);
            }
        }

        if(setMedDevIds.size() > 0){
            for(CMPL123CME__MEDDEV__c objMEDDEV
                : [SELECT Id,(SELECT Id FROM Regulatory_Tasks__r WHERE Regulatory_Agency_Notification_Required__c = 'Yes'
                              AND (CMPL123_WF_Status__c = 'Closed-Done'
                                   OR CMPL123_WF_Status__c = 'Closed-Void')) FROM
                   CMPL123CME__MEDDEV__c WHERE Id IN: setMedDevIds]){
                       if(objMEDDEV.Regulatory_Tasks__r.size() > 0) {
                           mapMeddevsNew.get(objMEDDEV.Id).addError(System.Label.MEDDEV_Cannot_Waive);
                       }
                   }
        }

    }

    /**
    * @Method       : setDefaultsOnCreation
    * @Invoke       : Events from TriggerHandler before insert EventHandler
    * @Description  : Defect# 916, 1069, 1119. Set default values on MDI on creation for fields set
    *                 as requird by system but not for rgulatory.
    * @Return       : N/A
    * @Params       : List<CMPL123CME__MEDDEV__c> newMDIRecords
    **/
    public static void setDefaultsOnCreation(List<CMPL123CME__MEDDEV__c> newMDIRecords) {
        for(CMPL123CME__MEDDEV__c mdi : newMDIRecords){
            if(mdi.CMPL123CME__Manufacturer_Remedial_Action__c == null
               && mdi.CMPL123CME__Type_of_Report__c  =='Final report'){
                   mdi.CMPL123CME__Manufacturer_Remedial_Action__c = 'NA';
               }
            //defect #1119
            if(mdi.CMPL123CME__NCA_Reference_Number__c == null){
                mdi.CMPL123CME__NCA_Reference_Number__c = 'Unknown';
            }
            //defect #1069
            if(mdi.CMPL123CME__Medical_Device_Distributed_Countries__c == null
               && (mdi.CMPL123CME__Type_of_Report__c  =='Final report'
                   || mdi.CMPL123CME__Type_of_Report__c  =='Combined initial and final report')){
                       mdi.CMPL123CME__Medical_Device_Distributed_Countries__c = 'N/A';
                   }
        }
    }

    /**
    * @Method       : setDueDateOnMDI
    * @Invoke       : Events from TriggerHandler before insert/update EventHandler
    * @Description  : Defect# 903 and 915, Set default due date on MDI on creation and reporrt type change.
    * @Return       : N/A
    * @Params       : List<CMPL123CME__MEDDEV__c> newMDIRecords, Map<Id, CMPL123CME__MEDDEV__c> oldRecordMap
    **/
    public static void setDueDateOnMDI(List<CMPL123CME__MEDDEV__c> newMDIRecords, Map<Id, CMPL123CME__MEDDEV__c> oldRecordMap) {
        Set<Id> medEvalIdSet = new Set<Id>();
        Set<Id> submissionTypeIdSet = new Set<Id>();
        //collect all the parent medical eval record Ids where type of report is modified or due date is blank
        for(CMPL123CME__MEDDEV__c mdi : newMDIRecords){
            CMPL123CME__MEDDEV__c oldMdi = Trigger.isUpdate && oldRecordMap != null ? oldRecordMap.get(mdi.Id) : null;
            if(mdi.Submission_Due_Date__c == null
               || (oldRecordMap != null && mdi.CMPL123CME__Type_of_Report__c != oldMdi.CMPL123CME__Type_of_Report__c)){
                   medEvalIdSet.add(mdi.Medical_Evaluation__c);
                   submissionTypeIdSet.add(mdi.Submission_Type__c);
               }
            //For final and combined final expected date is not requried, setting to blank
            if(mdi.CMPL123CME__Expected_Date_of_Next_Report__c != null && (mdi.CMPL123CME__Type_of_Report__c == 'Combined initial and final report'
                                                                           || mdi.CMPL123CME__Type_of_Report__c == 'Final report')){
                                                                               mdi.CMPL123CME__Expected_Date_of_Next_Report__c = null;
                                                                           }
        }
        //If set is not empty, query all the related Med Eval
        if(medEvalIdSet.size() > 0){

            Map<Id, CMPL123CME__Questionnaire__c> queriedMedEvalMap = new Map<Id, CMPL123CME__Questionnaire__c>([SELECT Id, Follow_Up_Awareness_Date__c,
                                                                                                                 Initial_Awareness_Date__c FROM CMPL123CME__Questionnaire__c WHERE Id =: medEvalIdSet]);

            Map<Id, Country_Submission_Type__c> queriedsubmissionTypeMap = new Map<Id, Country_Submission_Type__c>([SELECT Id, Calendar_Days__c
                                                                                                                    FROM Country_Submission_Type__c WHERE Id IN: submissionTypeIdSet]);
            for(CMPL123CME__MEDDEV__c mdi : newMDIRecords){
                CMPL123CME__MEDDEV__c oldMdi = Trigger.isUpdate && oldRecordMap != null ? oldRecordMap.get(mdi.Id) : null;
                if(mdi.Submission_Due_Date__c == null
                   || (oldRecordMap != null && mdi.CMPL123CME__Type_of_Report__c != oldMdi.CMPL123CME__Type_of_Report__c)){
                       CMPL123CME__Questionnaire__c queriedMedEvalRecord = queriedMedEvalMap != null && queriedMedEvalMap.get(mdi.Medical_Evaluation__c) != null
                           ? queriedMedEvalMap.get(mdi.Medical_Evaluation__c) : null;

                       Integer mdiCalenderDays = queriedsubmissionTypeMap != null && queriedsubmissionTypeMap.get(mdi.Submission_Type__c) != null
                           && queriedsubmissionTypeMap.get(mdi.Submission_Type__c).Calendar_Days__c != null
                           ? Integer.valueOf(queriedsubmissionTypeMap.get(mdi.Submission_Type__c).Calendar_Days__c) : 0;

                       if(mdi.CMPL123CME__Type_of_Report__c == 'Initial report' || mdi.CMPL123CME__Type_of_Report__c == 'Combined initial and final report'){
                           if(queriedMedEvalRecord != null && queriedMedEvalRecord.Initial_Awareness_Date__c != null &&  mdiCalenderDays != null
                              && (mdi.Submission_Due_Date__c != (queriedMedEvalRecord.Initial_Awareness_Date__c + mdiCalenderDays))){
                                  mdi.Submission_Due_Date__c = queriedMedEvalRecord.Initial_Awareness_Date__c + mdiCalenderDays;
                              }
                       } else{
                           if(queriedMedEvalRecord != null && queriedMedEvalRecord.Follow_Up_Awareness_Date__c != null){
                               mdi.Submission_Due_Date__c = queriedMedEvalRecord.Follow_Up_Awareness_Date__c + 30;
                           }
                       }
                   }
            }
        }
    }

    /**
    * @Method       : checkRequiredFields
    * @Invoke       : Before updte events of the trigger upon closing the mdi
    * @Description  : Defect# 70, disable validation on required fields for migrated MDIs.
    * @Return       : N/A
    * @Params       : List<CMPL123CME__MEDDEV__c> newMDIRecords, Map<Id, CMPL123CME__MEDDEV__c> oldRecordMap
    **/
    public static void checkRequiredFieldsUponClosing(Map<Id,CMPL123CME__MEDDEV__c> mapMeddevsNew, Map<Id, CMPL123CME__MEDDEV__c> mapMeddevsOld) {
        List<Schema.FieldSetMember> requiredUponClose = SObjectType.CMPL123CME__MEDDEV__c.FieldSets.RequiredUponClose.getFields();
        User migrationUser = [Select Id FROM User WHERE UserName = :System.Label.Migration_User_Name];
        Map<Id, List<String>> emptyFieldsByMDIId = new Map <Id, List<String>>();
        for (CMPL123CME__MEDDEV__c newMDI : mapMeddevsNew.values()) {
            if (newMDI.CMPL123_WF_Status__c == 'Closed-Done'
                    && mapMeddevsOld.get(newMDI.Id).CMPL123_WF_Status__c == 'Pending Follow Up Creation'
                    && newMDI.OwnerId != migrationUser.Id) {
                emptyFieldsByMDIId = getEmptyRequiredFieldsMap(requiredUponClose, newMDI);
            }
        }
        for (Id mdiId : emptyFieldsByMDIId.keySet()) {
            String emptyFields = String.join(emptyFieldsByMDIId.get(mdiId), ', ');
            if (!String.isBlank(emptyFields)) {
                mapMeddevsNew.get(mdiId).addError(System.Label.The_Following_fields_are_required +' ' + emptyFields + '.');
            }
        }
    }

    /**
    * @Method       : populateMap
    * @Invoke       : From checkRequiredFields method
    * @Description  : Defect# 70, disable validation on required fields for migrated MDIs.
    * @Return       : N/A
    * @Params       : List<CMPL123CME__MEDDEV__c> newMDIRecords, Map<Id, CMPL123CME__MEDDEV__c> oldRecordMap
    **/
    private static void populateMap(Map<Id, List<String>> emptyFieldsByMDIId, Id recordId, String fieldLabel) {
        if (!emptyFieldsByMDIId.containsKey(recordId)) {
            emptyFieldsByMDIId.put(recordId, new List<String> {fieldLabel});
        } else {
            emptyFieldsByMDIId.get(recordId).add(fieldLabel);
        }
    }

      /**
    * @Method       : getEmptyRequiredFieldsMap
    * @Invoke       : From checkRequiredFields method
    * @Description  : Defect# 70, disable validation on required fields for migrated MDIs.
    * @Return       : N/A
    * @Params       : List<CMPL123CME__MEDDEV__c> newMDIRecords, Map<Id, CMPL123CME__MEDDEV__c> oldRecordMap
    **/
    private static Map<Id, List<String>> getEmptyRequiredFieldsMap(List<Schema.FieldSetMember> requiredUponClose, CMPL123CME__MEDDEV__c newMDI) {
        Map<Id, List<String>> emptyFieldsByMDIId = new Map <Id, List<String>>();
        for (Schema.FieldSetMember requiredField : requiredUponClose) {
            Object fieldValue = newMDI.get(requiredField.getFieldPath());
            if (null == fieldValue) {
                populateMap(emptyFieldsByMDIId, newMDI.Id, requiredField.getLabel());
            } else if (fieldValue instanceof String && String.isBlank(((String) fieldValue))) {
                populateMap(emptyFieldsByMDIId, newMDI.Id, requiredField.getLabel());
            }
        }
        return emptyFieldsByMDIId;
    }

    /**
    * @Method       : updateTicketLastModifiedDate
    * @Invoke       : Events from Trigger after insert/update
    * @Description  : To update parent record "LastModifiedDate" field based on child records
    * @Return       : N/A
    * @Params       : N/A
    **/
    // Defect #123/CHARM-2729: added method to update parent tickets
    public static void updateTicketLastModifiedDate(){
        // Defect #123/CHARM-2729: prevent multiple updates of the ticket in the same transaction
        if(!UpdateParentUtility.isTicketUpdated || !ComplaintTriggerHandler.isTicketInserting){
            Set<Id> setComplaintIdToUpdate = new Set<Id>();
            for (CMPL123CME__MEDDEV__c objRecord : (List<CMPL123CME__MEDDEV__c>)Trigger.new) {
                Id ticketId = objRecord.CMPL123CME__Complaint__c;
                if (ticketId != null) {
                    setComplaintIdToUpdate.add(ticketId);
                }
            }
            if(setComplaintIdToUpdate.size() > 0){
                UpdateParentUtility.ticketTriggerPreventFlag = true;
                UpdateParentUtility.updateparent(setComplaintIdToUpdate);
                // Defect #123/CHARM-2729: disable ticket trigger logic only for UpdateParentUtility.updateparent method execution
                UpdateParentUtility.ticketTriggerPreventFlag = false;
            }
        }
    }

    /*
    * @Method       : checkEditableOnPendingStatus.
    * @Description  : To check edit access on Pending statuses.
    * @Invoke       : Events from CMPL123CME_MEDDEV_AuditTrigger on before update.
    * @Return       : N/A.
    * @Params       : String wfStatusAPIName.
    */
    // Defect HC #100/CHARM-3518 : check edit access on Pending statuses
    public static void checkEditableOnPendingStatus(String wfStatusAPIName){
        Map<Id,CMPL123CME__MEDDEV__c> newMDIs = (Map<Id,CMPL123CME__MEDDEV__c>)Trigger.newMap;
        Map<Id,CMPL123CME__MEDDEV__c> oldMDIs = (Map<Id,CMPL123CME__MEDDEV__c>)Trigger.oldMap;
        Set<String> editableFields = new Set<String>();
        Set<String> lockedStatuses = new Set<String>();
        List<Schema.FieldSetMember> fieldMembers = new List<Schema.FieldSetMember>();

        for (Id recordId : newMDIs.keySet()) {
            sObject newRecord = newMDIs.get(recordId);
            sObject oldRecord = oldMDIs.get(recordId);
            String newWFStatus = (String) newRecord.get(wfStatusAPIName);
            if (newWFStatus == oldRecord.get(wfStatusAPIName)) {
                if (newWFStatus == 'Pending Follow Up Creation') {
                    fieldMembers = SObjectType.CMPL123CME__MEDDEV__c.FieldSets.Editable_on_Pending_Follow_Up.getFields();
                    lockedStatuses = new Set<String> {'Pending Follow Up Creation'};
                    break;
                } else if (newWFStatus == 'Pending Final Review') {
                    fieldMembers = SObjectType.CMPL123CME__MEDDEV__c.FieldSets.Editable_on_Pending_Final_Review.getFields();
                    lockedStatuses = new Set<String> {'Pending Final Review'};
                    break;
                }
            }
        }
        for(Schema.FieldSetMember fieldMember: fieldMembers) {
            editableFields.add(fieldMember.getFieldPath());
        }
        if (lockedStatuses.size() > 0) {
            CustomRecordLockingUtil.validateRecordEdit(Trigger.newMap, Trigger.oldMap, wfStatusAPIName, lockedStatuses, editableFields);
        }
    }

    /*
    * @Method       : executeLogicFromWFRules.
    * @Description  : TWD Upgrade issue - this method contains logic from Workflow Rules with Field Updates on MEDDEV.
    * @Invoke       : From CMPL123CME_MEDDEV_AuditTrigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void executeLogicFromWFRules() {
        List<CMPL123CME__MEDDEV__c> newList = (List<CMPL123CME__MEDDEV__c>) Trigger.new;
        Map<Id, CMPL123CME__MEDDEV__c> oldMap = (Map<Id, CMPL123CME__MEDDEV__c>) Trigger.oldMap;

        Set<Id> medEvalIds = new Set<Id>();
        Set<Id> countryIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> complaintIds = new Set<Id>();
        Set<Id> registeredSiteIds = new Set<Id>();

        for (CMPL123CME__MEDDEV__c newMD :newList) {
            if (null != newMD.Medical_Evaluation__c) {
                medEvalIds.add(newMD.Medical_Evaluation__c);
            }

            if (null != newMD.Country__c) {
                countryIds.add(newMD.Country__c);
            }

            if (null != newMD.Product__c) {
                productIds.add(newMD.Product__c);
            }

            if (null != newMD.CMPL123CME__Complaint__c) {
                complaintIds.add(newMD.CMPL123CME__Complaint__c);
            }

            if (null != newMD.Registered_Site__c) {
                registeredSiteIds.add(newMD.Registered_Site__c);
            }

            if (null != newMD.Related_Product__c) {
                productIds.add(newMD.Related_Product__c);
            }
        }

        Map<Id, CMPL123CME__Questionnaire__c> medEvals = new Map<Id, CMPL123CME__Questionnaire__c>([
            SELECT Id, Date_of_Incidence__c, Describe_Event_or_Problem__c, Patient_Outcome__c, Initial_Awareness_Date__c, Initial_Follow_Up_Mfg_Analysis__c,
                Final_Mfg_Analysis__c, CMPL123CME__Complaint__c, CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c, CMPL123CME__Complaint__r.RecordType.DeveloperName, CMPL123CME__Complaint__r.Service_Type__c, B2_Outcomes_attributed_to_AE__c
            FROM CMPL123CME__Questionnaire__c
            WHERE Id IN :medEvalIds
        ]);

        Map<Id, Country__c> countries = new Map<Id, Country__c>([
            SELECT Id, NCA_Address__c, NCA_Name__c
            FROM Country__c
            WHERE Id IN :countryIds
        ]);

        Map<Id, Product_Ticket__c> productTickets = new Map<Id, Product_Ticket__c>([
            SELECT Id, Product_List_Number__c, Product_Brand_Name__c, Batch_Lot_Serial__c, Software_Version__c, Product__r.Device_Nomenclature_Code__c,
                Product__r.Device_Nomenclature_Text__c, Product__r.Notified_Body_ID__c, Product__r.Name
            FROM Product_Ticket__c
            WHERE Id IN :productIds
        ]);

        Map<Id, CMPL123CME__Complaint__c> complaints = new Map<Id, CMPL123CME__Complaint__c>([
            SELECT Id, Serial__c, CMPL123CME__Customer__r.Contact_Address_Line_1__c, CMPL123CME__Customer__r.Contact_Address_Line_2__c,
                CMSNext_Ticket_Number__c
            FROM CMPL123CME__Complaint__c
            WHERE Id IN :complaintIds
        ]);

        Map<Id, CMPL123CME__Registered_Site__c> registeredSites = new Map<Id, CMPL123CME__Registered_Site__c>([
            SELECT Id, Authorised_Rep_Contact__c, Authorised_Rep_E_mail__c, Authorised_Rep_Fax__c, Authorised_Rep_Name__c, Authorised_Rep_Phone__c,
                Authorised_Rep_Postcode__c
            FROM CMPL123CME__Registered_Site__c
            WHERE Id IN :registeredSiteIds
        ]);

        for (CMPL123CME__MEDDEV__c newMD :newList) {
            Boolean wfStatusIsChanged = Trigger.isInsert
                || (Trigger.isUpdate && newMD.CMPL123_WF_Status__c != oldMap.get(newMD.Id).CMPL123_WF_Status__c);

            Boolean wfActionIsChanged = Trigger.isInsert
                || (Trigger.isUpdate && newMD.CMPL123_WF_Action__c != oldMap.get(newMD.Id).CMPL123_WF_Action__c);

            //  Auto set Date of this report
            if (wfActionIsChanged && newMD.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Submit_To_Regulatory) {
                newMD.CMPL123CME__Report_Date__c = Date.today();
            }

            if (Trigger.isInsert && null != newMD.Medical_Evaluation__c) {
                //  Autoset Registration Number
                if (null != medEvals.get(newMD.Medical_Evaluation__c).CMPL123CME__Complaint__c
                        && null != medEvals.get(newMD.Medical_Evaluation__c).CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c) {
                    String ticketRecordTypeName = medEvals.get(newMD.Medical_Evaluation__c).CMPL123CME__Complaint__r.RecordType.DeveloperName;

                    newMD.Registration_Number__c = medEvals.get(newMD.Medical_Evaluation__c).CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c
                        + '('
                        + (ticketRecordTypeName == AspenConstants.STR_Service
                            ? medEvals.get(newMD.Medical_Evaluation__c).CMPL123CME__Complaint__r.Service_Type__c + ' '
                            : '')
                        + ticketRecordTypeName
                        + ')';
                }

                //  Set Classification of incident to Death
                if (medEvals.get(newMD.Medical_Evaluation__c).B2_Outcomes_attributed_to_AE__c == 'Death'
                        && newMD.CMPL123CME__Type_of_Report__c != 'Follow-up report') {
                    newMD.CMPL123CME__Classification_of_Incident__c = 'Death';
                }
            }

            //  Clear Follow Up Required?
            if (wfStatusIsChanged && newMD.CMPL123_WF_Status__c == AspenConstants.STR_Pending_Follow_Up_Creation) {
                newMD.Follow_Up_Required__c = '';
            }

            //  ADDS3 update NCA Address, Recipient (Name of NCA) fields from country in MDI
            if (Trigger.IsInsert && null != newMD.Country__c) {
                newMD.CMPL123CME__Address_of_National_Competent_Authority__c = countries.get(newMD.Country__c).NCA_Address__c;
                newMD.CMPL123CME__Recipient_Name_of_NCA__c = null != countries.get(newMD.Country__c).NCA_Name__c
                    ? countries.get(newMD.Country__c).NCA_Name__c
                    : newMD.CMPL123CME__Recipient_Name_of_NCA__c;
            }

            if (newMD.CMPL123CME__Type_of_Report__c != 'Follow-up report') {
                //  ADDS3 update default values in MDI
                newMD.CMPL123CME__If_usage_of_med_device_is_others_specify__c = null == newMD.CMPL123CME__If_usage_of_med_device_is_others_specify__c
                    ? 'IVD, Medical Device'
                    : newMD.CMPL123CME__If_usage_of_med_device_is_others_specify__c;

                newMD.CMPL123CME__Medical_Device_Current_Location__c = null == newMD.CMPL123CME__Medical_Device_Current_Location__c
                    ? 'At customer site'
                    : newMD.CMPL123CME__Medical_Device_Current_Location__c;

                newMD.CMPL123CME__Model_Number__c = null == newMD.CMPL123CME__Model_Number__c
                    ? 'NA'
                    : newMD.CMPL123CME__Model_Number__c;

                newMD.CMPL123CME__Whether_Manufacturer_Aware__c = null == newMD.CMPL123CME__Whether_Manufacturer_Aware__c
                    ? 'No'
                    : newMD.CMPL123CME__Whether_Manufacturer_Aware__c;

                //  ADDS3 update medical evaluation based fields in MDI
                if (Trigger.IsInsert && null != newMD.Medical_Evaluation__c) {
                    newMD.CMPL123CME__Incident_Date__c = medEvals.get(newMD.Medical_Evaluation__c).Date_of_Incidence__c;
                    newMD.CMPL123CME__Incident_Description_Narrative__c = medEvals.get(newMD.Medical_Evaluation__c).Describe_Event_or_Problem__c;
                    newMD.CMPL123CME__PatientOutcome__c = medEvals.get(newMD.Medical_Evaluation__c).Patient_Outcome__c;
                    newMD.CMPL123CME__Manufacturer_Awareness_Date__c = medEvals.get(newMD.Medical_Evaluation__c).Initial_Awareness_Date__c;
                    newMD.CMPL123CME__Manufacturer_Disclaimer__c = 'Submission of this report does not, in itself, represent a conclusion by the manufacturer '
                        + 'and/or authorized representative or the National Competent Authority that the content of this report is complete or accurate, that '
                        + 'the medical device(s) listed failed in any manner and/or that the medical device(s) caused or contributed to the alleged death or '
                        + 'deterioration in the state of the health of any person.';
                }

                //  Update Accessories / associated devices based on Related Product
                if (null != newMD.Related_Product__c) {
                    newMD.CMPL123CME__Accessories__c = productTickets.get(newMD.Related_Product__c).Product__r.Name
                        + ','
                        + productTickets.get(newMD.Related_Product__c).Product_List_Number__c
                        + ','
                        + productTickets.get(newMD.Related_Product__c).Batch_Lot_Serial__c;
                }

                //  ADDS3 update product-ticket based fields in MDI
                if ((Trigger.isInsert && null != newMD.Product__c) || (Trigger.isUpdate && newMD.Product__c != oldMap.get(newMD.Id).Product__c)) {
                    Boolean serialValueIsSameInProductAndTicket = productTickets.get(newMD.Product__c).Batch_Lot_Serial__c == 
                    (null != newMD.CMPL123CME__Complaint__c ? complaints.get(newMD.CMPL123CME__Complaint__c).Serial__c : null);

                    newMD.CMPL123CME__Catalogue_Number__c = productTickets.get(newMD.Product__c).Product_List_Number__c;
                    newMD.CMPL123CME__Commercial_Name__c = productTickets.get(newMD.Product__c).Product_Brand_Name__c;

                    newMD.CMPL123CME__Lot_Numbers__c = !serialValueIsSameInProductAndTicket
                        ? productTickets.get(newMD.Product__c).Batch_Lot_Serial__c
                        : 'N/A';

                    newMD.CMPL123CME__Serial_Numbers__c = serialValueIsSameInProductAndTicket
                        ? productTickets.get(newMD.Product__c).Batch_Lot_Serial__c
                        : 'N/A';

                    newMD.CMPL123CME__Nomenclature_Code__c = null != productTickets.get(newMD.Product__c).Product__r.Device_Nomenclature_Code__c
                        ? productTickets.get(newMD.Product__c).Product__r.Device_Nomenclature_Code__c
                        : newMD.CMPL123CME__Nomenclature_Code__c;

                    newMD.CMPL123CME__Nomenclature_Text__c = null != productTickets.get(newMD.Product__c).Product__r.Device_Nomenclature_Text__c
                        ? productTickets.get(newMD.Product__c).Product__r.Device_Nomenclature_Text__c
                        : newMD.CMPL123CME__Nomenclature_Text__c;

                    newMD.CMPL123CME__Notified_Body_ID_Number__c = null != productTickets.get(newMD.Product__c).Product__r.Notified_Body_ID__c
                        ? productTickets.get(newMD.Product__c).Product__r.Notified_Body_ID__c
                        : newMD.CMPL123CME__Notified_Body_ID_Number__c;

                    newMD.CMPL123CME__Software_Version__c = null != productTickets.get(newMD.Product__c).Software_Version__c
                        ? productTickets.get(newMD.Product__c).Software_Version__c
                        : newMD.CMPL123CME__Software_Version__c;
                }

                //  ADDS3 update Reference number by manufacturer in MDI
                if (Trigger.isInsert && null != newMD.CMPL123CME__Complaint__c) {
                    newMD.CMPL123CME__HealthCare_Address__c = complaints.get(newMD.CMPL123CME__Complaint__c).CMPL123CME__Customer__r.Contact_Address_Line_1__c
                        + '\n'
                        + complaints.get(newMD.CMPL123CME__Complaint__c).CMPL123CME__Customer__r.Contact_Address_Line_2__c;

                    newMD.CMPL123CME__Manufacturer_Reference_Number__c = complaints.get(newMD.CMPL123CME__Complaint__c).CMSNext_Ticket_Number__c;
                }

                //  ADDS3 update registered site contact based fields in MDI
                if ((Trigger.isInsert && null != newMD.Registered_Site__c)
                        || (Trigger.isUpdate && newMD.Registered_Site__c != oldMap.get(newMD.Id).Registered_Site__c)) {
                    System.debug(registeredSites.get(newMD.Registered_Site__c));
                    newMD.CMPL123CME__Authorised_Representative_Contact__c = registeredSites.get(newMD.Registered_Site__c).Authorised_Rep_Contact__c;
                    newMD.CMPL123CME__Authorised_Representative_Email__c = registeredSites.get(newMD.Registered_Site__c).Authorised_Rep_E_mail__c;
                    newMD.CMPL123CME__Authorised_Representative_Fax__c = registeredSites.get(newMD.Registered_Site__c).Authorised_Rep_Fax__c;
                    newMD.CMPL123CME__Authorised_Representative_Name__c = registeredSites.get(newMD.Registered_Site__c).Authorised_Rep_Name__c;
                    newMD.CMPL123CME__Authorised_Representative_Phone__c = registeredSites.get(newMD.Registered_Site__c).Authorised_Rep_Phone__c;
                    newMD.CMPL123CME__Authorised_Representative_Postal_Code__c = registeredSites.get(newMD.Registered_Site__c).Authorised_Rep_Postcode__c;
                }

                //  ADDS3 update type of report based fields in MDI
                if (Trigger.isInsert || (Trigger.isUpdate && newMD.CMPL123CME__Type_of_Report__c != oldMap.get(newMD.Id).CMPL123CME__Type_of_Report__c)) {
                    newMD.CMPL123CME__Manufacturer_Preliminary_Analysis__c = null != newMD.Medical_Evaluation__c
                            && null != medEvals.get(newMD.Medical_Evaluation__c).Initial_Follow_Up_Mfg_Analysis__c
                            && (newMD.CMPL123CME__Type_of_Report__c == 'Initial report' || newMD.CMPL123CME__Type_of_Report__c == 'Follow-up report')
                        ? medEvals.get(newMD.Medical_Evaluation__c).Initial_Follow_Up_Mfg_Analysis__c
                        : newMD.CMPL123CME__Manufacturer_Preliminary_Analysis__c;

                    newMD.CMPL123CME__Manufacturer_Device_Analysis_Results__c = null != newMD.Medical_Evaluation__c
                            && null != medEvals.get(newMD.Medical_Evaluation__c).Final_Mfg_Analysis__c
                            && (newMD.CMPL123CME__Type_of_Report__c == 'Final report' || newMD.CMPL123CME__Type_of_Report__c == 'Combined initial and final report')
                        ? medEvals.get(newMD.Medical_Evaluation__c).Final_Mfg_Analysis__c
                        : newMD.CMPL123CME__Manufacturer_Device_Analysis_Results__c;
                }
            }
        }
    }
}