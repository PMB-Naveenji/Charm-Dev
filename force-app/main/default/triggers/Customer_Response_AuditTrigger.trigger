/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : Customer_Response_AuditTrigger.
* @Why   : Handles all the customization involved on Customer_Response__c object.
* @When  : 07-FEB-2019.
* @Where : From Customer_Response__c object events.
* ----------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    07-FEB-2019            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                    Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                    Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    22-JUN-2020            #123.1/CHARM-2878             Adjusted parent Ticket Last Modified Date update'.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue             Added 'CustomerResponseTriggerHandler.executeLogicFromWFRules()' method calls.
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar             29-NOV-2023            CHaRM-R4/BTSIT10110           Commented the Last Modified Date Time field Update code from Before Insert and Update Event.
                                                                                And the Field will be updated only when Assignee Name is changed and Status is Closed-Done.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

trigger Customer_Response_AuditTrigger on Customer_Response__c (before insert, before update,before delete,after insert,after update){
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        TicketUtil.addTrace('Customer_Response_AuditTrigger');
        // Def #123.1/CHARM-2878: added processedTicketIds
        Set<Id> processedTicketIds = new Set<Id>();

        // 18APR19 - Added for Fixing TIBCO Query Redesign
        if(Trigger.isBefore && UserInfo.getProfileId() != System.Label.Integration_Profile_ID
            && (Trigger.isInsert || Trigger.isUpdate)) {
                //CHaRM-R4 : Commented the Last Modified Date Time field Update code from Before Insert and Update Event.
                //           And the Field will be updated only when Assignee Name is changed and Status is Closed-Done.
                //           Moved the Logic to Flows "Update Last Modified Date And Time Field".
           /* for(Customer_Response__c objCustomerResponse: Trigger.New) {
                objCustomerResponse.Last_Modified_Date_Time__c = System.now();
            }*/
        }

        if(Trigger.isInsert && Trigger.isBefore){
             CustomerResponseTriggerHandler.beforeEventHandler();

            // TWD Upgrade issue - FIX START
            CustomerResponseTriggerHandler.executeLogicFromWFRules();
            // TWD Upgrade issue - FIX END
        }
        /* After Insert */
        else if(Trigger.isInsert && Trigger.isAfter){
            CMPL123.AuditHandler.handleAudit();

            // 07FEB19 - AQC#120 - CPU TIME LIMIT
            if(!CustomerResponseTriggerHandler.TTFlag) {
                CustomerResponseTriggerHandler.TTFlag = true;
                ADDTranslations.ChildObjectTranslations();
            }

            // 28FEB19 - DEF#120 - Removed the Batch processing
            if(ComplaintTriggerHandler.customCustomerResponse) { return; }

            if(TicketUpdateUtility.executeFlag) {
                TicketUpdateUtility.executeFlag = false;
                Set<Id> parentIds = new Set<Id>();
                List< Customer_Response__c > newCustomerResponses = (List< Customer_Response__c >)Trigger.New;
                for(Customer_Response__c objCustomerRes : newCustomerResponses){
                    parentIds.add(objCustomerRes.Event__c);
                }
                if(parentIds != null && parentIds.size() > 0){
                    // Call the utility method to update the parent
                    processedTicketIds = TicketUpdateUtility.updateParentOnChildUpdate(parentIds);
                }
            }
            // Def #123.1/CHARM-2878: update parent ticket LastModifiedDate field if operation come from integration
            UpdateParentUtility.updateTicketLastModifiedDate(Trigger.new, processedTicketIds, 'Event__c', false);
        }
        /* Before Update */
        else if(Trigger.isUpdate && Trigger.isBefore) {
            CustomerResponseTriggerHandler.isUpdated = true;
            // 28FEB19 - DEF#120 - Removed the Batch processing
            if(ComplaintTriggerHandler.customCustomerResponse) { return; }
            // Def #123.1/CHARM-2878: prevent logic execution if only Last Modified Date is updating
            if (!CustomerResponseTriggerHandler.isLastModifiedDateUpdating) {
                CustomerResponseTriggerHandler.beforeEventHandler();
            }

            // TWD Upgrade issue - FIX START
            CustomerResponseTriggerHandler.executeLogicFromWFRules();
            // TWD Upgrade issue - FIX END

            CMPL123.AuditHandler.handleAudit();
        }
        /* After Update */
        else if(Trigger.isUpdate && Trigger.isAfter) {
            // 28FEB19 - DEF#120 - Removed the Batch processing
            if(ComplaintTriggerHandler.customCustomerResponse) { return; }
            CMPL123.AuditHandler.handleAudit();

            // Def #123.1/CHARM-2878: prevent logic execution if only Last Modified Date is updating
            if (!CustomerResponseTriggerHandler.isLastModifiedDateUpdating) {
                CustomerResponseTriggerHandler.afterEventHandler();
                CustomerResponseTriggerTempHandler.afterUpdateEventHandler();

                // 07FEB19 - AQC#120 - CPU TIME LIMIT
                if(!CustomerResponseTriggerHandler.TTFlag) {
                    CustomerResponseTriggerHandler.TTFlag = true;
                    ADDTranslations.ChildObjectTranslations();
                }

                if(TicketUpdateUtility.executeFlag){
                    TicketUpdateUtility.executeFlag = false;
                    Set<Id> parentIds = new Set<Id>();
                    List< Customer_Response__c > newCustomerResponses = (List< Customer_Response__c >)Trigger.New;
                    for(Customer_Response__c objCustomerRes : newCustomerResponses){
                        parentIds.add(objCustomerRes.Event__c);
                    }
                    if(parentIds != null && parentIds.size() > 0){
                        // Call the utility method to update the parent
                        processedTicketIds = TicketUpdateUtility.updateParentOnChildUpdate(parentIds);
                    }
                }
                // Def #123.1/CHARM-2878: update parent ticket LastModifiedDate field if operation come from integration
                UpdateParentUtility.updateTicketLastModifiedDate(Trigger.new, processedTicketIds, 'Event__c', false);
            }
        }

        /* Before Delete */
        else if(Trigger.isDelete && Trigger.isBefore) {
            CMPL123.AuditHandler.handleAudit();
        }
        /* After Delete */
        else if(Trigger.isDelete && Trigger.isAfter) {
             // Place your code.
        }
    }
}