/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDCustomActivityTriggerhandler
* @Why   : Handles all the customization involved on custom Activity object
* @When  : 06-APR-2017
* @Where : From Activity_AuditTrigger Trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID            Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*    Admin     				06-APR-2017			    Work ID / Case ID          Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                   12-MAY-2020             Defect #96 (CHARM-2507)    Modified (Audit trail code added on beforeUpdate)
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                   15-06-2020              Code Audit                 Updated Jira reference with reference from Defect Tracker. 
*                                                                              Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                   22-JUNE-2020            #123.1/CHARM-2878                         Adjusted custom and standars Last Modified
                                                                                            Date update
*  --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    28-DEC-2020            TWD Upgrade issue          Related to WF Step issue. Added updateWorkField and External Id set functionality
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDCustomActivityTriggerhandler extends TriggerHandler {
    // Def #123.1/CHARM-2878: added processedTicketIds
    Set<Id> processedTicketIds = new Set<Id>();
    
    /**
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public override void beforeInsert() {
        //TWD Upgrade issue start. WF: Update External Id
        List<Activity__c> activities = (List<Activity__c>)Trigger.New;
        updateWorkField(activities, null);
        //TWD Upgrade issue end.
    }
    
    /**
    * @Method       : afterInsert
    * @Invoke       : Events from TriggerHandler after insert
    * @Description  : To handle all the logic in after insert event
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public override void afterInsert() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        if(TicketUpdateUtility.executeFlag){
            TicketUpdateUtility.executeFlag = false;
            //Update parent ticket 
            Set<Id> parentIds = new Set<Id>();
            List< Activity__c > newActivities = (List< Activity__c >)Trigger.New;
            for(Activity__c objActivity : newActivities){
                parentIds.add(objActivity.Complaint__c); 
            }
            if(parentIds != null && parentIds.size() > 0){
                // Call the utility method to update the parent
                processedTicketIds = TicketUpdateUtility.updateParentOnChildUpdate(parentIds);
            }
        }
        // Def #123.1/CHARM-2878: update parent ticket standard and custom Last Modified Date fields
        if (UserInfo.getProfileId() != System.Label.Integration_Profile_ID) {
            UpdateParentUtility.updateTicketLastModifiedDate(Trigger.new, processedTicketIds, 'Complaint__c', true); 
        }
        //TWD Upgrade issue start. WF: Update External Id
        List<Activity__c> activities = [SELECT Id, External_ID__c FROM Activity__c WHERE Id in: Trigger.NewMap.keySet()];
        for (Activity__c activity: activities ) {
            if (activity.External_ID__c == null) {
                activity.External_ID__c = activity.Id;
            }
        }
        update activities ;
        //TWD Upgrade issue end.
    }

    /**
    * @Method       : beforeUpdate
    * @Invoke       : Events from TriggerHandler before update
    * @Description  : To handle all the logic in before update event
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public override void beforeUpdate() {
        //TWD Upgrade issue start. WF: Update External Id
        List<Activity__c> activities = (List<Activity__c>)Trigger.New;
        Map<Id, Activity__c> oldActivityById = (Map<Id, Activity__c>)Trigger.OldMap;
        updateWorkField(activities, oldActivityById );
        //TWD Upgrade issue end.        
        //Defect #96 (CHARM-2507) start. Fields should be tracked in before Update
        CMPL123.AuditHandler.handleAudit();
        //Defect #96 (CHARM-2507) end
    }
    
    /**
    * @Method       : afterUpdate
    * @Invoke       : Events from TriggerHandler after update
    * @Description  : To handle all the logic in after update event
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public override void afterUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        if(TicketUpdateUtility.executeFlag){
            TicketUpdateUtility.executeFlag = false;
            // Call the utility method to update the parent
            Set<Id> parentIds = new Set<Id>();
            for(Activity__c act: (List<Activity__c>)Trigger.new) {
                parentIds.add(act.Complaint__c);
            }
            if(parentIds != null && parentIds.size() > 0){
                processedTicketIds = TicketUpdateUtility.updateParentOnChildUpdate(parentIds);
            }
        }
        // Def #123.1/CHARM-2878: update parent ticket standard and custom Last Modified Date fields
        if (UserInfo.getProfileId() != System.Label.Integration_Profile_ID) {
            UpdateParentUtility.updateTicketLastModifiedDate(Trigger.new, processedTicketIds, 'Complaint__c', true); 

        }
    }

    /**
    * @Method       : beforeDelete
    * @Invoke       : Events from TriggerHandler before delete
    * @Description  : To handle all the logic in before delete event
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }   
     
    /**
    * @Method       : afterDelete
    * @Invoke       : Events from TriggerHandler after delete
    * @Description  : To handle all the logic in after delete event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void afterDelete() {
    }
    
     /*
    * @Method       : updateWorkField.
    * @Description  : To handle all the logic from WF: Update Work Done Code & Description and code.
    * @Invoke       : From Activity_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : List <Activity__c> activities, Map <Id, Activity__c> oldActivitiesById
    */
    public static void updateWorkField(List <Activity__c> activities, Map <Id, Activity__c> oldActivitiesById) {
        for (Activity__c activity: activities ) {
            if (oldActivitiesById == null || (oldActivitiesById!= null 
                && (oldActivitiesById.get(activity.Id).Work_Done_Code__c != activity.Work_Done_Code__c || oldActivitiesById.get(activity.Id).Work_Done_Description__c != activity.Work_Done_Description__c ) )) {
                       if (activity.Work_Done_Code__c != null || activity.Work_Done_Description__c != null) {
                            activity.Work_Done_Code_and_Description__c = '';
                        }
                        if (activity.Work_Done_Code__c != null) {
                            activity.Work_Done_Code_and_Description__c = activity.Work_Done_Code__c;
                        } 
                        if(activity.Work_Done_Description__c != null) {
                             activity.Work_Done_Code_and_Description__c += ' ' + activity.Work_Done_Description__c;
                        }
            } 
        }
    }
}