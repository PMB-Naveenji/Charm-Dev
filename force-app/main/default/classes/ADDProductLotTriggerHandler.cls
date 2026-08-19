/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDProductLotTriggerHandler
* @Why   : Handles all the customization involved on Product Lot object.
* @When  : 06-APR-2017
* @Where : From Product_Lot_AuditTrigger Trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Admin                06-APR-2017         Work ID / Case ID         Created.
*      rsitc                09-June-2020        #123/CHARM-2729           Added updateProductTicketsAndInvestigations method.
*      Charm COE            7/17/2025           IPDR-105                  Added new method preventDeletionForNonCreator.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ADDProductLotTriggerHandler extends TriggerHandler {
    
    
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
    }
    
/**
* @Method       : beforeUpdate
* @Invoke       : Events from TriggerHandler before update
* @Description  : To handle all the logic in before update event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeInsert() {
        //addCurrentTimeToDateFields(); 
    }

    public override void beforeUpdate() {
        CMPL123.AuditHandler.handleAudit(); 
        //addCurrentTimeToDateFields(); 
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
    }
    
/**
* @Method       : beforeDelete
* @Invoke       : Events from TriggerHandler before update
* @Description  : To handle all the logic in before update event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        
        //Added - W-000365
        preventDeletionifParentClosedPEReview();
        //Added - W-000365
    }   
    
/**
* @Method       : afterDelete
* @Invoke       : Events from TriggerHandler after delete
* @Description  : To handle all the logic in after delete event
* @Return       : N/A
* @Params       : N/A
**/  
    public override void afterDelete() {
        UpdateProdEval(Trigger.Old);
    }   
    

    // private static void addCurrentTimeToDateFields() {
    //     Map<Id,Product_Lot__c> oldMap = (Map<Id,Product_Lot__c>)Trigger.OldMap;
    //     List<Product_Lot__c> newList = (List<Product_Lot__c>)Trigger.New;
    //     Boolean isInsert = oldMap == null;
    //     for (Product_Lot__c item : newList){
    //         if(((isInsert && item.Device_Expiration_Date__c != null) || 
    //             (oldMap != null &&  item.Device_Expiration_Date__c != oldMap.get(item.Id).Device_Expiration_Date__c))) {
    //             item.Device_Expiration_Date_DT__c = AspenUtil.getDateWithCurrentGMTtime(item.Device_Expiration_Date__c);
    //         }
    //         if(((isInsert && item.Device_Manufacturing_Date__c != null) || 
    //             (oldMap != null && item.Device_Manufacturing_Date__c != oldMap.get(item.Id).Device_Manufacturing_Date__c))) {
    //             item.Device_Manufacturing_Date_DT__c = AspenUtil.getDateWithCurrentGMTtime(item.Device_Manufacturing_Date__c);
    //         }
    //     }
    // }
    
    
    /**
* @Method       : preventDeletionifParentClosedPEReview
* @Invoke       : from ADDProductLotTriggerHandler class
* @Description  : Update IPDR-105 : prevent product lot deletion if parent closed/PE Review/Conclude
* @Return       : N/A
* @Params       : N/A
**/ 
    private static void preventDeletionifParentClosedPEReview() {
        //Added - IPDR-105 Fetch blocked statuses from custom metadata
        Set<String> blockedStatuses = new Set<String>();
        for (Blocked_Status_for_PL_Deletion__mdt blockedStatus : [SELECT label FROM Blocked_Status_for_PL_Deletion__mdt]) {
            blockedStatuses.add(blockedStatus.label);
        }
        Map<Id,Product_Lot__c> mapOldProductLots = (Map<Id,Product_Lot__c>)Trigger.OldMap;
        for(Product_Lot__c objProductLot : [SELECT Id,Product_Evaluation_Investigation__c, Product_Evaluation_Investigation__r.CMPL123_WF_Status__c FROM Product_Lot__c WHERE Id =: mapOldProductLots.keySet()]){
            String status = objProductLot.Product_Evaluation_Investigation__r.CMPL123_WF_Status__c;
            if (objProductLot.Product_Evaluation_Investigation__c != null && blockedStatuses.contains(status)) {
                mapOldProductLots.get(objProductLot.Id).addError(System.label.PreventDeleteProductlotwhenProdEvalClosedPEReview);
            }else{
                preventDeletionForNonCreator();
            }
        }
        //Added - IPDR-105
    } 
    
/**
* @Method       : UpdateProdEval
* @Invoke       : from ADDProductLotTriggerHandler class
* @Description  : Added W-000563 : Updating Prod Eval field after deleting Product-Lot
* @Return       : N/A
* @Params       : List<Product_Lot__c> lstProductLots
**/ 
    public static void updateProdEval(List<Product_Lot__c> lstProductLots) {
        if(!lstProductLots.isEmpty()){
            List<Id> lstInvestigationIds = new List<Id>();
            
            for(Product_Lot__c objProductLot : lstProductLots){
                if(objProductLot.Product_Evaluation_Investigation__c != null){
                    lstInvestigationIds.add(objProductLot.Product_Evaluation_Investigation__c);
                }
            } 
            
            if(lstInvestigationIds.size() > 0) {
                List<CMPL123CME__Investigation__c> lstInvestigations = new List<CMPL123CME__Investigation__c>();
                for(CMPL123CME__Investigation__c objInvestigation : [SELECT Id, Has_Product_Lot_Child__c, (SELECT Id FROM Product_Lots__r LIMIT 1) FROM CMPL123CME__Investigation__c WHERE Id IN :lstInvestigationIds AND Has_Product_Lot_Child__c = true]) {
                    if(objInvestigation.Product_Lots__r.size() == 0) {
                        objInvestigation.Has_Product_Lot_Child__c = false;
                        lstInvestigations.add(objInvestigation);
                    }
                }
                
                if(lstInvestigations.size() > 0) {
                    update lstInvestigations;
                } 
            }
            
        } 
    }

          /**
    * @Method       : updateProductTicketsAndInvestigations
    * @Invoke       : Events from Trigger after insert/update
    * @Description  : To update parent record "LastModifiedDate" field based on child records
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    // Defect #123/CHARM-2729: added method to update parent Product Tickets and Invetigations if they weren't updated in current transaction
    public static void updateProductTicketsAndInvestigations() {
        //To update Investigation/Evaluation records
        Set<Id> investigationRecordIdSet = new Set<Id>();
        //To update Products- Ticket records                
        Set<Id> productticketRecordIdSet = new Set<Id>();                
        for (Product_Lot__c productlotCode : (List<Product_Lot__c>)Trigger.new){
            investigationRecordIdSet.add(productlotCode.Product_Evaluation_Investigation__c);
            productticketRecordIdSet.add(productlotCode.Product_Name__c);                       
        } 
        if (UpdateParentUtility.flag){
            UpdateParentUtility.flag = false;
            UpdateParentUtility.updateparent_trend(productticketRecordIdSet);           
        } 
        if (!UpdateParentUtility.isInvestigationUpdated) {
            UpdateParentUtility.isInvestigationUpdated = true;
            UpdateParentUtility.isInvestigationLastModifDateUpdating = true;
            UpdateParentUtility.updateparent_trend(investigationRecordIdSet);
            UpdateParentUtility.isInvestigationLastModifDateUpdating = false;
        }
    }  

    /*
    * @Method       : preventDeletionForNonCreator
    * @Description  : Added IPDR-105 : To prevent product lot deletion if Non Business Admin User tries to delete the record.
    * @Invoke       : From ADDProductLotTriggerHandler class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void preventDeletionForNonCreator() {
        Id currentUserId = UserInfo.getUserId();        
        // Fetch current user's profile
        User currentUser = [ SELECT Id, Profile.Name FROM User WHERE Id = :currentUserId LIMIT 1 ];
        String integrationUserProfileName = Label.ASPEN_Integration;
        String businessAdminPermissionSet = Label.Business_Admin;
        Set<String> currentUserPermissionSetNames = new Set<String>();
        // Get assigned permission sets for current user
        for (PermissionSetAssignment psa : [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :currentUserId]) {
            currentUserPermissionSetNames.add(psa.PermissionSet.Name);
        }
        Boolean isBusinessAdminUser = currentUserPermissionSetNames.contains(businessAdminPermissionSet);
        
        Set<String> lotNumbers = new Set<String>();
        Set<Id> createdByIds = new Set<Id>();
        Map<Id,Id> productLotToInvestigationMap = new Map<Id,Id>();
        // Collect lot names and creators from deleted records
        for (Product_Lot__c productlot : (List<Product_Lot__c>) Trigger.old) {
            if (productlot.Name != null) {
                lotNumbers.add(productlot.Name);
            }
            if (productlot.CreatedById != null) {
                createdByIds.add(productlot.CreatedById);
            }
        }
        // Map of creators of the Product Lot records
            Map<Id, User> createdByUserMap = new Map<Id, User>([SELECT Id, Profile.Name FROM User WHERE Id IN :createdByIds]);
        // Find lot numbers with pending (unacknowledged) MDC tickets
        Set<String> lotsWithPendingMDCs = new Set<String>();
        for (CMPL123__MDC_Ticket__c mdc : [SELECT Id, Name,CMPL123__Related_Record_Name__c FROM CMPL123__MDC_Ticket__c WHERE CMPL123__Related_Record_Name__c IN :lotNumbers AND CMPL123__All_Acks_Received__c = false]) {
            lotsWithPendingMDCs.add(mdc.CMPL123__Related_Record_Name__c);
        }
        // Validate deletion rules per product lot
        for (Product_Lot__c productlot : (List<Product_Lot__c>) Trigger.old) {
            User createdByUser = createdByUserMap.get(productlot.CreatedById);
            Boolean isCreatedByIntegrationUser = createdByUser != null && createdByUser.Profile.Name == integrationUserProfileName;
           // Error if related MDC records are not acknowledged
            if (lotsWithPendingMDCs.contains(productlot.Name)) {
                productlot.addError(Label.Product_Lot_Delete_Error_Message_for_MDC);
            }
            // Error if current user is trying to delete records created by System generated or Integration user.
            else if (productlot.System_Generated_Flag__c || isCreatedByIntegrationUser) {
                productlot.addError(Label.Product_Lot_Delete_Error_Message_for_Admin);
            } 
            // Error if user is neither the creator nor a business admin
            else if (!isBusinessAdminUser && currentUserId != productlot.CreatedById) {
                productlot.addError(Label.Product_Lot_Delete_Error_Message);
            }
        }
    }
}