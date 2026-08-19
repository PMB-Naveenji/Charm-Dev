/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDMDRequestTriggerHandler.
* @Why   : Handles all the customization involved on Meaningful Data Request object.
* @When  : 06-APR-2017.
* @Where : From Meaningful_Data_Request_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin 				06-APR-2017			   Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob 				30-DEC-2019			   1660                        Modified beforeUpdate().
* --------------------------------------------------------------------------------------------------------------------------------------
* dskak 				19-MAR-2019			   #39/CHARM-2197              Modified beforeUpdate().
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 15-JUN-2020            Code Audit                  Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc 				22-JUN-2020			   #123.1/CHARM-2878           Added custom Last Modified Date update.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 30-JUL-2020            Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDMDRequestTriggerHandler extends TriggerHandler {
    // Def #123.1/CHARM-2878: added processedTicketIds
    Set<Id> processedTicketIds = new Set<Id>();

    /*
    * @Method       : beforeInsert.
    * @Description  : To handle all the logic in before insert event.
    * @Invoke       : From Meaningful_Data_Request_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeInsert() {
        ADDS5MDRTriggerHandler.fieldUpdates();
    }

    /*
    * @Method       : afterInsert.
    * @Description  : To handle all the logic in after insert event.
    * @Invoke       : From Meaningful_Data_Request_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterInsert() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();

        ADDS5MDRTriggerHandler.fieldUpdates();

        if (TicketUpdateUtility.executeFlag) {
            TicketUpdateUtility.executeFlag = false;
            //Update parent ticket
            Set<Id> parentIds = new Set<Id>();
            List<Meaningful_Data_Request__c> newMeaningfulDataRequests = (List<Meaningful_Data_Request__c>) Trigger.New;
            for (Meaningful_Data_Request__c objMeaningfulDataReq : newMeaningfulDataRequests) {
                parentIds.add(objMeaningfulDataReq.Ticket__c);
            }
            if (parentIds != null && parentIds.size() > 0) {
                // Call the utility method to update the parent
                processedTicketIds = TicketUpdateUtility.updateParentOnChildUpdate(parentIds);
            }
        }
        // Def #123.1/CHARM-2878: update parent ticket standard and custom Last Modified Date fields
        UpdateParentUtility.updateTicketLastModifiedDate(Trigger.new, processedTicketIds, 'Ticket__c', true);
    }

    /*
    * @Method       : beforeUpdate.
    * @Description  : To handle all the logic in before update event.
    * @Invoke       : From Meaningful_Data_Request_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeUpdate() {
        //  Defect #39 fix BEGIN
        // Check the user's permissions sets to avoid the following (example) scenario: one user role is able to change
        // 'Request Status' to 'Completed' of an MDR record which is created by another user role.
        checkUserPermSets();
        //  Defect #39 fix END

        //Defect 1660 fix BEGIN
        CMPL123.AuditHandler.handleAudit();
        //Defect 1660 fix END

        ADDS5MDRTriggerHandler.fieldUpdates();
    }

    /*
    * @Method       : afterUpdate.
    * @Description  : To handle all the logic in after update event.
    * @Invoke       : From Meaningful_Data_Request_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterUpdate() {
        //Defect 1660 fix BEGIN
        CMPL123.AuditHandler.handleAudit();
        //Defect 1660 fix END
        ADDS5MDRTriggerHandler.afterEventHandler();
        if (TicketUpdateUtility.executeFlag) {
            TicketUpdateUtility.executeFlag = false;
            //Update parent ticket
            Set<Id> parentIds = new Set<Id>();
            List<Meaningful_Data_Request__c> newMeaningfulDataRequests = (List<Meaningful_Data_Request__c>) Trigger.New;
            for (Meaningful_Data_Request__c objMeaningfulDataReq : newMeaningfulDataRequests) {
                parentIds.add(objMeaningfulDataReq.Ticket__c);
            }
            if (parentIds != null && parentIds.size() > 0) {
                // Call the utility method to update the parent
                processedTicketIds = TicketUpdateUtility.updateParentOnChildUpdate(parentIds);
            }
        }
        // Def #123.1/CHARM-2878: update parent ticket standard and custom Last Modified Date fields
        UpdateParentUtility.updateTicketLastModifiedDate(Trigger.new, processedTicketIds, 'Ticket__c', true);
    }

    /*
    * @Method       : beforeDelete.
    * @Description  : To handle all the logic in before delete event.
    * @Invoke       : From Meaningful_Data_Request_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterDelete.
    * @Description  : To handle all the logic in after delete event.
    * @Invoke       : From Meaningful_Data_Request_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterDelete() {
    }

    /*
    * @Method       : checkUserPermSets.
    * @Description  : To check the user's permission sets.
    * @Invoke       : From ADDMDRequestTriggerHandler class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
        private static void checkUserPermSets() {
        Map<Id, Meaningful_Data_Request__c> newMap = (Map<Id, Meaningful_Data_Request__c>) Trigger.newMap;
        Map<Id, Meaningful_Data_Request__c> oldMap = (Map<Id, Meaningful_Data_Request__c>) Trigger.oldMap;

        List<Id> permSetIdsToFilter = new List<Id>();
        for (PermissionSet permSet :[SELECT Id FROM PermissionSet
                                     WHERE Name LIKE 'X00%'
                                     OR Name = 'X123Compliance_Permission_Set_for_Platform_User']) {
                                         permSetIdsToFilter.add(permSet.Id);
                                     }

        System.debug('permSetIdsToFilter' + permSetIdsToFilter);

        List<PermissionSetAssignment> permSetAssignmentsOfCurrentUser = [SELECT PermissionSetId, AssigneeId
                                                                         FROM PermissionSetAssignment
                                                                         WHERE AssigneeId = :UserInfo.getUserId()];

        System.debug('permSetAssignmentsOfCurrentUser' + permSetAssignmentsOfCurrentUser);
        Boolean currentUserIsBusinessAdmin = false;
        Set<Id> currentUserPermSetIds = new Set<Id>();

        for (PermissionSetAssignment assignment :permSetAssignmentsOfCurrentUser) {
            if (!permSetIdsToFilter.contains(assignment.PermissionSetId)) {
                currentUserPermSetIds.add(assignment.PermissionSetId);
            }
        }

        System.debug('currentUserPermSetIds' + currentUserPermSetIds);
        List<PermissionSet> currentUserPermSets = [SELECT Id FROM PermissionSet
                                                   WHERE Name = 'Business_Admin'
                                                   AND Id IN :currentUserPermSetIds];

        System.debug('currentUserPermSets' + currentUserPermSets);
        if (currentUserPermSets.size() > 0) {
            return;
        }

        Map<Id, List<Id>> creatorIdPermSets = new Map<Id, List<Id>>();
        List<Id> permSetIdsOfCurrentUser = new List<Id>();

        for (PermissionSetAssignment assignment :permSetAssignmentsOfCurrentUser) {
            if (!permSetIdsToFilter.contains(assignment.PermissionSetId)) {
                permSetIdsOfCurrentUser.add(assignment.PermissionSetId);
            }
        }

        System.debug('permSetIdsOfCurrentUser' + permSetIdsOfCurrentUser);
        creatorIdPermSets.put(Id.valueOf(UserInfo.getUserId()), permSetIdsOfCurrentUser);

        Map<Id, Id> mdrIdCreatedByIds = new Map<Id, Id>();
        for (Meaningful_Data_Request__c mdr :[SELECT CreatedBy.Id FROM Meaningful_Data_Request__c WHERE Id IN: newMap.keySet()]) {
            mdrIdCreatedByIds.put(mdr.Id, mdr.CreatedBy.Id);
        }

        System.debug('mdrIdCreatedByIds' + mdrIdCreatedByIds);
        List<PermissionSetAssignment> permSetAssignments = [SELECT PermissionSetId, AssigneeId
                                                            FROM PermissionSetAssignment
                                                            WHERE AssigneeId IN :mdrIdCreatedByIds.values()];

        System.debug('permSetAssignments' + permSetAssignments);
        Map<Id, List<Id>> userIdPermSetIds = new Map<Id, List<Id>>();

        for (PermissionSetAssignment assignment :permSetAssignments) {
            if (!permSetIdsToFilter.contains(assignment.PermissionSetId)) {
                if (userIdPermSetIds.get(assignment.AssigneeId) == null) {
                    userIdPermSetIds.put(assignment.AssigneeId, new List<Id>{assignment.PermissionSetId});
                } else {
                    userIdPermSetIds.get(assignment.AssigneeId).add(assignment.PermissionSetId);
                }
            }
        }

        System.debug('userIdPermSetIds' + userIdPermSetIds);
        for (Meaningful_Data_Request__c mdr :newMap.values()) {
            Boolean requestStatusIsChanged = oldMap.get(mdr.Id).Request_Status__c != newMap.get(mdr.Id).Request_Status__c;
            Id createrId = mdrIdCreatedByIds.get(mdr.Id);
            Boolean userPermSetIsValid = false;

            System.debug('createrId' + createrId);
            if (userIdPermSetIds.get(createrId) != null) {
                System.debug('userIdPermSetIds.get(createrId) != null' + userIdPermSetIds.get(createrId) != null);
                for (Id permSetId :userIdPermSetIds.get(createrId)) {
                    System.debug('permSetId' + permSetId);
                    if (creatorIdPermSets.get(UserInfo.getUserId()).contains(permSetId)) {
                        userPermSetIsValid = true;
                    }
                }
            }

            if (requestStatusIsChanged && !userPermSetIsValid) {
                newMap.get(mdr.Id).addError(System.Label.Status_Is_Not_Changeable);
            }
        }
    }
}