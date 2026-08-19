/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS4TranslationTaskTiggerHandler.
* @Why   : Handles different scenarios from Translation Task Trigger.
* @When  : 23-MAR-2017.
* @Where : From ADDTranslationTaskTriggerhandler class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                  Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                  Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue           Added 'executeLogicFromWFRules()' method to move logic from
*                                                                               Workflow Rules with Field Updates on Translation Task to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    05-FEB-2021            TWD Upgrade issue           Fixed defects #146 and #147 in 'executeLogicFromWFRules()' method.
* --------------------------------------------------------------------------------------------------------------------------------------
* Lakshman                 15-FEB-2021            TWD Upgrade issue           Fixed defects #156 in 'executeLogicFromWFRules()' method.
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar             25-SEP-2024            CHARM R5/IPDR 620           Updated the method 'beforeEventHandler'
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDS4TranslationTaskTiggerHandler {
    /*
    * @Method       : beforeEventHandler
    * @Invoke       : From ADDTranslationTaskTriggerhandler class
    * @Description  : Before Trigger Event Handling Common Method
    * @Return       : N/A
    * @Params       : N/A
    */
    public static void beforeEventHandler() {
        List<Translation_Task__c> newTranslationTasks = (List<Translation_Task__c>)Trigger.New;
        Map<Id,Translation_Task__c> taskNewMap =(Map<Id,Translation_Task__c>)Trigger.NewMap;
        Map<Id,Translation_Task__c> taskOldMap =(Map<Id,Translation_Task__c>)Trigger.oldMap;

        Map<String, Country__c> countryMap = new Map<String, Country__c>();
        //Added W-000054
        Set<String> setRelatedComplaintIds = New Set<String>();

        for(Country__c country : [SELECT Id, Name, Primary_Vigilance_Contact__c, Language__c,
                                  Preferred_Translation_Vendor__c,Division__c  FROM Country__c]){
                                      //Added - W-000338 - Key combination
                                      //CHaRM R5: Fields were not updated in Translation task due to Case Mismatch in the Country object.
                                      // Converting the Country map to Uppercase by adding 'toUpperCase' - IPDR 620
                                      countryMap.put((country.Name+'-'+country.Division__c).toUpperCase(),country);
                                  }

        for(Translation_Task__c translationTask : newTranslationTasks){
            // Added - W-000338
            //CHaRM R5: Fields were not updated in Translation task due to Case Mismatch in the Country object.
            // Converting the Country map to Uppercase by adding 'toUpperCase' - IPDR 620
            String strKey = (translationTask.Country_Name__c+'-'+translationTask.Division__c).toUpperCase();
            // Added - W-000338
            translationTask.Vendor_Name__c =
                (countryMap.get(strKey) != null &&
                 countryMap.get(strKey).Name.equalsIgnoreCase(translationTask.Country_Name__c) && translationTask.Vendor_Name__c == null)
                ? countryMap.get(strKey).Preferred_Translation_Vendor__c
                : translationTask.Vendor_Name__c;

            translationTask.Language__c = countryMap.get(strKey) != null
                ? countryMap.get(strKey).Language__c
                : translationTask.Language__c;
            translationTask.Urgency__c = (translationTask.Urgency__c == null || translationTask.Urgency__c == '')
                ? (translationTask.pRE_Status__c == 'Yes' ? 'Rush' : 'Normal')
                : translationTask.Urgency__c;
        }

        if(Trigger.isUpdate){
            setReopenRationale(taskNewMap, taskOldMap);
        }

        //  TWD Upgrade issue - Fix START
        executeLogicFromWFRules();
        //  TWD Upgrade issue - Fix END
    }

    /*
    * @Method       : afterEventHandler
    * @Invoke       : From ADDTranslationTaskTriggerhandler class
    * @Description  : After Trigger Event Handling Common Method
    * @Return       : N/A
    * @Params       : N/A
    */
    public static void afterEventHandler() {
        List<Translation_Task__c> newTranslationTasks = (List<Translation_Task__c>)Trigger.New;
        Map<Id, Translation_Task__c> oldTranslationMap = (Map<Id, Translation_Task__c>)Trigger.oldMap;
        Map<String, Translation_Task__c> ticketWithAdhocMap = new Map<String, Translation_Task__c>();
        Set<String> eligibleTasks = new Set<String>();
        Set<String> closedTasks = new Set<String>();
        Set<String> closedAttachmentTasks = new Set<String>();
        Set<String> complaintIds = new Set<String>();
        //Added - W-000054
        Set<Id> setReopenedTranslationTasks = new Set<Id>();
        //Added - W-000054

        for(Translation_Task__c translationTask : newTranslationTasks){
            if(translationTask.Assignee_Name__c != null
               && (Trigger.isInsert || (Trigger.isUpdate && oldTranslationMap.get(translationTask.Id).Assignee_Name__c != translationTask.Assignee_Name__c))
               && translationTask.CMPL123_WF_Status__c == 'Opened'){
                   eligibleTasks.add(translationTask.Id);

               }else if(translationTask.Adhoc_Fields__c != null
                        && (Trigger.isInsert || (Trigger.isUpdate && oldTranslationMap.get(translationTask.Id).Adhoc_Fields__c != translationTask.Adhoc_Fields__c))  //Def #289
                        //Added - W-00074 - 08/08/2018 -- translationTask.CMPL123_WF_Status__c == null
                        //TBD - Class Code Optimization

                        && (translationTask.CMPL123_WF_Status__c == null || translationTask.CMPL123_WF_Status__c == 'Opened'
                            || translationTask.CMPL123_WF_Status__c == 'In Process')){
                                ticketWithAdhocMap.put(translationTask.Parent_Ticket__c,translationTask);
                            }else if(translationTask.CMPL123_WF_Status__c == 'Closed-Done'
                                     && (Trigger.isInsert || (Trigger.isUpdate && oldTranslationMap.get(translationTask.Id).CMPL123_WF_Status__c != translationTask.CMPL123_WF_Status__c))){
                                         if (translationTask.RecordTypeId == Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Text Translation').getRecordTypeId()) {
                                             closedTasks.add(translationTask.Id);
                                         } else {
                                             closedAttachmentTasks.add(translationTask.Id);
                                         }
                                     }
            // W-001268
            if(Trigger.isUpdate){
                //Added - W-000054
                if(translationTask.CMPL123_WF_Status__c == 'In Process'
                   && (translationTask.CMPL123_WF_Action__c == 'Reopen' || translationTask.CMPL123_WF_Action__c == 'Send Back to In Process')
                   && translationTask.RecordTypeId == Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Attachment Translation').getRecordTypeId()
                   && translationTask.CMPL123_WF_Status__c != oldTranslationMap.get(translationTask.Id).CMPL123_WF_Status__c){
                       setReopenedTranslationTasks.add(translationTask.Id);
                   }
                //Added - W-000054

                if(translationTask.Parent_Ticket__c != null
                   && (translationTask.CMPL123_WF_Status__c == 'Closed-Done' || translationTask.CMPL123_WF_Status__c == 'Closed-Void') && oldTranslationMap != null
                   && translationTask.CMPL123_WF_Status__c != oldTranslationMap.get(translationTask.Id).CMPL123_WF_Status__c){
                       complaintIds.add(translationTask.Parent_Ticket__c);
                   }
            }
        }

        //Added - W-000054
        if(setReopenedTranslationTasks.size() > 0) {
            deleteAttachmentWhenTaskReopens(setReopenedTranslationTasks);
        }
        //Added - W-000054

        if(complaintIds.size() > 0) {
            CustomerResponseTriggerHandler.processEligibleComplaintsToComplete(complaintIds);
        }

        if(eligibleTasks.size() > 0){
            CMPL123__WF_Step__c wfStep = [SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,
                                          CMPL123__Start_Status__r.Name FROM CMPL123__WF_Step__c Where
                                          CMPL123__Start_Status__r.Name = 'Opened' AND CMPL123__End_Status__r.Name = 'In Process'
                                          AND CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Translation_Task'];
            List<CMPL123__WF_History__c> WFHistories = new list<CMPL123__WF_History__c>();
            List<Translation_Task__c> updatableTasks = new list<Translation_Task__c>();

            for (String taskId : eligibleTasks) {
                WFHistories.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(taskId, wfStep));
                updatableTasks.add(
                    new Translation_Task__c (
                        CMPL123_WF_Status__c = wfStep.CMPL123__End_Status__r.Name,
                        CMPL123_WF_Action__c = wfStep.CMPL123__Action__r.Name,
                        CMPL123_WF_Action_Performed_On__c = DateTime.now(),
                        CMPL123_WF_Action_Performed_By__c = Userinfo.getUserId(),
                        Id = taskId
                    )
                );
            }
            if(WFHistories.size() > 0 && updatableTasks.size() > 0) {
                Database.SaveResult[] srList = Database.update(updatableTasks, false);
                // Iterate through each returned result
                Integer counter = 0;
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        // Operation failed, so get all errors
                        for(Database.Error err : sr.getErrors()) {
                            Id failureRecordId = updatableTasks.get(counter).Id;
                            Trigger.newMap.get(failureRecordId).addError(err.getMessage());
                        }
                    }
                    counter++;
                }
                insert WFHistories;
            }
        } else if(ticketWithAdhocMap.keyset().size() > 0) {
            adhocTranslations(ticketWithAdhocMap);
        } else if(closedTasks.size() > 0 && !ADDTranslations.isExecutedTextAttachment) {
            ADDTranslations.updateApprovedTranslations(closedTasks);
        } else if(closedAttachmentTasks.size() > 0 && !ADDTranslations.isExecutedFileAttachment) {
            ADDTranslations.isExecutedFileAttachment = true;
            ADDTranslations.updateApprovedFileTranslations(closedAttachmentTasks);
        }

        //Added - W-000108 - 07/08/2018
        if(Trigger.isUpdate && TicketUtil.isFirstRun()){
            closeTicketBasedOnTraslationTasks(newTranslationTasks);
        }
    }

    /*
    * @Method       : adhocTranslations
    * @Invoke       : From ADDTranslationTaskTriggerhandler class
    * @Description  : When Translation Task Field Adhoc_Fields__c not empty, create Transaction Items
    * @Return       : N/A
    * @Params       : Map<String, Translation_Task__c> adhocWithTicketMap
    */
    private static void adhocTranslations(Map<String, Translation_Task__c> adhocWithTicketMap){
        // Added this code for Def #289 - 02/14/2019
        List<String> translationTaskIdList = new List<String>();
        for(Translation_Task__c translationTask : adhocWithTicketMap.values()){
            translationTaskIdList.add(translationTask.Id);
        }

        Map<String,Set<String>> ticketIdAndExtAdhocFsMap = new Map<String,Set<String>>();
        Map<String,Set<String>> ticketIdAndTItemRelRecMap  = new Map<String,Set<String>>();
        for(Translation_Item__c  translationItem : [SELECT Field_Name__c,Translation_Task__r.Parent_Ticket__c,Related_Record_Id__c FROM Translation_Item__c
                                                    WHERE Translation_Task__c IN : translationTaskIdList]){
                                                        if(ticketIdAndExtAdhocFsMap.size() > 0
                                                           && ticketIdAndExtAdhocFsMap.containsKey(translationItem.Translation_Task__r.Parent_Ticket__c)){
                                                               Set<String> existingAdhocFSet = ticketIdAndExtAdhocFsMap.get(translationItem.Translation_Task__r.Parent_Ticket__c);
                                                               existingAdhocFSet.add(translationItem.Field_Name__c);
                                                               ticketIdAndExtAdhocFsMap.put(translationItem.Translation_Task__r.Parent_Ticket__c,existingAdhocFSet);

                                                               Set<String> existingTItemsRecSet = ticketIdAndTItemRelRecMap.get(translationItem.Translation_Task__r.Parent_Ticket__c);
                                                               existingTItemsRecSet.add(translationItem.Related_Record_Id__c+'~'+translationItem.Field_Name__c);
                                                               ticketIdAndTItemRelRecMap.put(translationItem.Translation_Task__r.Parent_Ticket__c,existingTItemsRecSet);
                                                           }else{
                                                               ticketIdAndExtAdhocFsMap.put(translationItem.Translation_Task__r.Parent_Ticket__c,
                                                                                            new Set<String>{translationItem.Field_Name__c});

                                                               ticketIdAndTItemRelRecMap.put(translationItem.Translation_Task__r.Parent_Ticket__c,
                                                                                             new Set<String>{translationItem.Related_Record_Id__c+'~'+translationItem.Field_Name__c});

                                                           }
                                                    }
        //Ended

        List<Translation_Item__c> translationItems = new List<Translation_Item__c>();
        //Updated - W-000074 - 01/08/2018 - Below Query included "CMPL123CME__Customer__r.State__c"
        for(CMPL123CME__Complaint__c ticket :
            [SELECT Id, CMPL123CME__Customer__c, CMPL123CME__Customer__r.Name,
             CMPL123CME__Customer__r.Contact_Address_Line_1__c, CMPL123CME__Customer__r.Contact_Address_Line_2__c,
             CMPL123CME__Customer__r.City__c, CMPL123CME__Customer__r.State__c,
             (SELECT Id, Name__c, Occupation__c FROM Related_Contact__r) FROM CMPL123CME__Complaint__c
             WHERE Id IN :adhocWithTicketMap.keyset()]){

                 // Added this code for Def #289 - 02/14/2019
                 Set<String> translationRecAdhocFieldsSet = new Set<String>();
                 translationRecAdhocFieldsSet.addAll(adhocWithTicketMap.get(ticket.Id).Adhoc_Fields__c.split(';'));
                 //Ended

                 // Added code in the if condition criteria
                 if(translationRecAdhocFieldsSet.contains('Customer Name') //Def #289
                    && (ticketIdAndExtAdhocFsMap.isEmpty() || (ticketIdAndExtAdhocFsMap.containsKey(ticket.Id) && !(ticketIdAndExtAdhocFsMap.get(ticket.Id).contains('Customer Name'))))  //Def #289
                    && ticket.CMPL123CME__Customer__r.Name != null){
                        translationItems.add(new Translation_Item__c(
                            Translation_Task__c =  adhocWithTicketMap.get(ticket.Id).Id,
                            Field_Name__c = 'Customer Name',
                            Native__c = ticket.CMPL123CME__Customer__r.Name,
                            Related_Record_Id__c = ticket.CMPL123CME__Customer__c
                        ));
                    }
                 if(translationRecAdhocFieldsSet.contains('Customer Address Line 1') //Def #289
                    && (ticketIdAndExtAdhocFsMap.isEmpty() || (ticketIdAndExtAdhocFsMap.containsKey(ticket.Id) && !(ticketIdAndExtAdhocFsMap.get(ticket.Id).contains('Customer Address Line 1'))))  //Def #289
                    && ticket.CMPL123CME__Customer__r.Contact_Address_Line_1__c != null){
                        translationItems.add(new Translation_Item__c(
                            Translation_Task__c = adhocWithTicketMap.get(ticket.Id).Id,
                            Field_Name__c = 'Customer Address Line 1',
                            Native__c = ticket.CMPL123CME__Customer__r.Contact_Address_Line_1__c,
                            Related_Record_Id__c = ticket.CMPL123CME__Customer__c
                        ));
                    }
                 if(translationRecAdhocFieldsSet.contains('Customer Address Line 2')  //Def #289
                    && (ticketIdAndExtAdhocFsMap.isEmpty() || (ticketIdAndExtAdhocFsMap.containsKey(ticket.Id) && !(ticketIdAndExtAdhocFsMap.get(ticket.Id).contains('Customer Address Line 2')))) //Def #289
                    && ticket.CMPL123CME__Customer__r.Contact_Address_Line_2__c != null){
                        translationItems.add(new Translation_Item__c(
                            Translation_Task__c =  adhocWithTicketMap.get(ticket.Id).Id,
                            Field_Name__c = 'Customer Address Line 2',
                            Native__c = ticket.CMPL123CME__Customer__r.Contact_Address_Line_2__c,
                            Related_Record_Id__c = ticket.CMPL123CME__Customer__c
                        ));
                    }
                 if(translationRecAdhocFieldsSet.contains('Customer City')  //Def #289
                    && (ticketIdAndExtAdhocFsMap.isEmpty() || (ticketIdAndExtAdhocFsMap.containsKey(ticket.Id) && !(ticketIdAndExtAdhocFsMap.get(ticket.Id).contains('Customer City')))) //Def #289
                    && ticket.CMPL123CME__Customer__r.City__c != null){
                        translationItems.add(new Translation_Item__c(
                            Translation_Task__c =  adhocWithTicketMap.get(ticket.Id).Id,
                            Field_Name__c = 'Customer City',
                            Native__c = ticket.CMPL123CME__Customer__r.City__c,
                            Related_Record_Id__c = ticket.CMPL123CME__Customer__c
                        ));
                    }

                 //Added - W-000074 - 01/08/2018 - For creating Translation Item with Customer State - Start
                 if(translationRecAdhocFieldsSet.contains('Customer State')   //Def #289
                    && (ticketIdAndExtAdhocFsMap.isEmpty() || (ticketIdAndExtAdhocFsMap.containsKey(ticket.Id) && !(ticketIdAndExtAdhocFsMap.get(ticket.Id).contains('Customer State')))) //Def #289
                    && ticket.CMPL123CME__Customer__r.State__c != null){
                        translationItems.add(new Translation_Item__c(
                            Translation_Task__c =  adhocWithTicketMap.get(ticket.Id).Id,
                            Field_Name__c = 'Customer State',
                            Native__c = ticket.CMPL123CME__Customer__r.State__c,
                            Related_Record_Id__c = ticket.CMPL123CME__Customer__c
                        ));
                    }
                 //Added - W-000074 - 01/08/2018 - For creating Translation Item with Customer State - End

                 for(Contact__c con : ticket.Related_Contact__r) {

                     if(translationRecAdhocFieldsSet.contains('Contact Name')   //Def #289
                        && (ticketIdAndTItemRelRecMap.isEmpty() || (ticketIdAndTItemRelRecMap.containsKey(ticket.Id) && !(ticketIdAndTItemRelRecMap.get(ticket.Id).contains(con.Id+'~Contact Name'))))  //Def #289
                        && con.Name__c != null){
                            translationItems.add(new Translation_Item__c(
                                Translation_Task__c =  adhocWithTicketMap.get(ticket.Id).Id,
                                Field_Name__c = 'Contact Name',
                                Native__c = con.Name__c,
                                Related_Record_Id__c = con.Id
                            ));
                        }
                     if(translationRecAdhocFieldsSet.contains('Contact Occupation')   //Def #289
                        && (ticketIdAndTItemRelRecMap.isEmpty()  || (ticketIdAndTItemRelRecMap.containsKey(ticket.Id) && !(ticketIdAndTItemRelRecMap.get(ticket.Id).contains(con.Id+'~Contact Occupation')))) //Def #289
                        && con.Occupation__c != null){
                            translationItems.add(new Translation_Item__c(
                                Translation_Task__c =  adhocWithTicketMap.get(ticket.Id).Id,
                                Field_Name__c = 'Contact Occupation',
                                Native__c = con.Occupation__c,
                                Related_Record_Id__c = con.Id
                            ));
                        }
                 }
             }
        if(translationItems.size() > 0) {
            insert translationItems;
        }
    }

    /*
    * @Method       : closeTicketBasedOnTraslationTasks
    * @Invoke       : From ADDTranslationTaskTriggerhandler class
    * @Description  : W-000108 - When all Translation Tasks related to ticket closed, based on ticket "MDC All ACKs Received?"
    *                 And "CMSNext Status" field values close ticket.
    * @Return       : N/A
    * @Params       : List<Translation_Task__c> lstTranslationTasksNew
    */
    private static void closeTicketBasedOnTraslationTasks(List<Translation_Task__c> lstTranslationTasksNew){
        //Store Related Ticket Ids
        Set<Id> setTicketIds = New Set<Id>();

        for(Translation_Task__c objTranslationTask : lstTranslationTasksNew){
            if(objTranslationTask.Parent_Ticket__c != null){
                setTicketIds.add(objTranslationTask.Parent_Ticket__c);
            }
        }

        if(setTicketIds.size() > 0){
            // W-000108
            TicketUtil.closeTicketBasedOnConditions(setTicketIds);
        }

    }

    /*
    * @Method       : deleteAttachmentWhenTaskReopens
    * @Invoke       : From ADDTranslationTaskTriggerhandler class
    * @Description  : W-000054 - If attachment is on translation task when reopening, delete attachments
    * @Return       : N/A
    * @Params       : Set<Id> setTaskIds
    */
    private static void deleteAttachmentWhenTaskReopens(Set<Id> setTaskIds){
        List<Attachment> lstAttachments = New List<Attachment>();
        for(Attachment objAttachment : [SELECT Id FROM Attachment WHERE ParentId IN: setTaskIds]){
            lstAttachments.add(objAttachment);
        }

        if(lstAttachments.size() > 0){
            delete lstAttachments;
        }
    }

    /*
    * @Method       : setReopenRationale
    * @Description  : used to set reopen rationale from workflow history
    * @Return       : N/A
    * @Params       : Map<Id,Translation_Task__c> newRecordMap,
    *               : Map<Id,Translation_Task__c> oldRecordMap
    */
    public static void setReopenRationale(Map<Id,Translation_Task__c> newRecordMap, Map<Id,Translation_Task__c> oldRecordMap){
                                              Translation_Task__c oldRecord;
                                              Translation_Task__c newRecord;
                                              if(newRecordMap.keyset().size() == 1){
                                                  for(Translation_Task__c sobj : newRecordMap.values()){
                                                      newRecord = sobj;
                                                      oldRecord = oldRecordMap.get(sobj.Id);
                                                  }
                                                  if(newRecord.CMPL123_WF_Action__c != null && newRecord.CMPL123_WF_Action__c.containsIgnorecase('Reopen')
                                                     && newRecord.CMPL123_WF_Action__c != oldRecord.CMPL123_WF_Action__c){
                                                         newRecord.Reopen_Rationale__c = ADDUtil.fetchReopenWorkflowHistory(newRecord.Id);
                                                     }
                                              }
                                          }

    /*
    * @Method       : executeLogicFromWFRules.
    * @Description  : TWD Upgrade issue - this method contains logic from Workflow Rules with Field Updates on Translation Task.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void executeLogicFromWFRules() {
        List<Translation_Task__c> newList = (List<Translation_Task__c>) Trigger.new;
        Map<Id, Translation_Task__c> oldMap = (Map<Id, Translation_Task__c>) Trigger.oldMap;

        Set<Id> complaintIds = new Set<Id>();
        Set<Id> vendorIds = new Set<Id>();

        for (Translation_Task__c newTT :newList) {
            if (null != newTT.Parent_Ticket__c) {
                complaintIds.add(newTT.Parent_Ticket__c);
            }

            if (null != newTT.Vendor_Name__c) {
                vendorIds.add(newTT.Vendor_Name__c);
            }
        }

        Map<Id, CMPL123CME__Complaint__c> complaints = new Map<Id, CMPL123CME__Complaint__c>([
            SELECT Id, CMSNext_Ticket_Number__c, RecordType.DeveloperName, Service_Type__c
            FROM CMPL123CME__Complaint__c
            WHERE Id IN :complaintIds
        ]);

        Map<Id, Translation_Vendor__c> vendors = new Map<Id, Translation_Vendor__c>([
            SELECT Id, Name
            FROM Translation_Vendor__c
            WHERE Id IN :vendorIds
        ]);

        for (Translation_Task__c newTT :newList) {
            if (Trigger.isInsert) {
                //  Update workflow rule.
                newTT.CMPL123Rule_Key_Value__c = 'Translation_Task';

                //  Autoset Registration Number
                if (null != newTT.Parent_Ticket__c && null != complaints.get(newTT.Parent_Ticket__c).CMSNext_Ticket_Number__c) {
                    String parentRecordType = complaints.get(newTT.Parent_Ticket__c).RecordType.DeveloperName;

                    newTT.Registration_Number__c = complaints.get(newTT.Parent_Ticket__c).CMSNext_Ticket_Number__c
                        + '('
                        + (parentRecordType == AspenConstants.STR_Service
                            ? complaints.get(newTT.Parent_Ticket__c).Service_Type__c + ' '
                            : '')
                        + parentRecordType
                        + ')';
                }
            }

            //Begin: Fix for defect 156
            Boolean check = newTT.CMPL123_WF_Status__c=='Opened' && newTT.Request_More_Information_Provided__c != null
            && newTT.Request_More_Information_Provided__c != ''
            && newTT.Request_More_Information_Provided__c != oldMap.get(newTT.Id).Request_More_Information_Provided__c;
            
			if (check) {
            newTT.CMPL123Task_Key_Value__c = 'TranslationOpentoInprogress';
			} 
			//End: Fix for defect 156

			Boolean wfActionIsChanged = Trigger.isInsert
                || (Trigger.isUpdate && newTT.CMPL123_WF_Action__c != oldMap.get(newTT.Id).CMPL123_WF_Action__c);

            if (!wfActionIsChanged) {
                continue;
            }

            DateTime actionPerformedOn = DateTime.now();
            String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

            //  Clear Approval Field
            if (newTT.CMPL123_WF_Action__c == AspenConstants.STR_Send_Back_To_In_Process) {
                newTT.Sent_to_Vendor_By__c = null;
                newTT.Sent_to_Vendor_On__c = null;
                newTT.Translation_Provided_by_Vendor_By__c = null;
                newTT.Translation_Provided_by_Vendor_On__c = null;
                newTT.Vendor_Received_By__c = null;
                newTT.Vendor_Received_On__c = null;
            }

            if (newTT.CMPL123_WF_Action__c == AspenConstants.STR_Reopen) {
                //  Field updates based on workflow actions
                newTT.Reopened_By__c = actionPerformedBy;
                newTT.Reopened_On__c = actionPerformedOn;

                //  Clear Approval Field on reopen
                newTT.Task_Completed_By__c = null;
                newTT.Task_Completion_Date__c = null;
                newTT.Sent_to_Vendor_By__c = null;
                newTT.Sent_to_Vendor_On__c = null;
                newTT.Translation_Provided_by_Vendor_By__c = null;
                newTT.Translation_Provided_by_Vendor_On__c = null;
                newTT.Vendor_Received_By__c = null;
                newTT.Vendor_Received_On__c = null;

                //  Clear Fields on WF Action Reopen
                if (newTT.CMPL123_WF_Status__c == AspenConstants.STR_In_Process) {
                    newTT.Void_Rationale__c = null;
                }
            }

            if (newTT.CMPL123_WF_Action__c == AspenConstants.STR_Populate_Translations) {
                //  Clear Fields on WF Action Reopen
                newTT.Task_Completed_By__c = actionPerformedBy;
                newTT.Task_Completion_Date__c = actionPerformedOn;

                //  Clear Reopen Fields
                newTT.Reopened_By__c = null;
                newTT.Reopened_On__c = null;
            }

            if (newTT.CMPL123_WF_Action__c == AspenConstants.STR_Promote) {
                //  Field updates based on workflow actions.
                newTT.Assigned_Date__c = Date.today();
                newTT.Promote_By__c = actionPerformedBy;
                newTT.Promote_On__c = actionPerformedOn;

                //  Field updates based on workflow actions
                newTT.Request_More_Information__c = '';
                newTT.CMPL123Task_Key_Value__c = '';
            }

            //  Clear Fields on WF Action Reopen
            if (newTT.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Void) {
                newTT.Task_Completion_Date__c = actionPerformedOn;
            }

            if (newTT.CMPL123_WF_Action__c == AspenConstants.STR_Translation_Provided_By_Vendor) {
                //  Field updates based on workflow actions.
                if (null != newTT.Vendor_Name__c) {
                    newTT.Translation_Provided_by_Vendor_By__c = vendors.get(newTT.Vendor_Name__c).Name;
                }

                //  Field updates based on workflow actions
                newTT.Translation_Provided_by_Vendor_On__c = actionPerformedOn;
            }

            //  Field updates based on workflow actions.
            if (newTT.CMPL123_WF_Action__c == AspenConstants.STR_Send_To_Vendor) {
                newTT.Sent_to_Vendor_By__c = actionPerformedBy;
                newTT.Sent_to_Vendor_On__c = actionPerformedOn;
            }

            if (newTT.CMPL123_WF_Action__c == AspenConstants.STR_Request_More_Information) {
                //  Workflow - Request More Info Provided
                Boolean updateKeyValue = newTT.Request_More_Information_Provided__c != null
                    && newTT.Request_More_Information_Provided__c != ''
                    && newTT.Request_More_Information_Provided__c != oldMap.get(newTT.Id).Request_More_Information_Provided__c;

                if (updateKeyValue) {
                    newTT.CMPL123Task_Key_Value__c = 'TranslationOpentoInprogress';
                }

                //  Field updates based on workflow actions
                newTT.Request_More_Information_Provided__c = '';

                //  Workflow - Request More Info
                newTT.Promote_By__c = null;
                newTT.Promote_On__c = null;
            }
        }
    }
}