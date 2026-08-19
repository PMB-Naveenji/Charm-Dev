/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Trend_Item_Trend_Bucket_AuditTrigger
* @Why   : To Handles all the customization involved on Trend_Item_Trend_Bucket__c object.
* @When  : 07-FEB-2019
* @Where : From Trend_Item_Trend_Bucket__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                  07-FEB-2019              Work ID / Case ID    Created.
*   rsitc                  09-JUNE-2020             #123/CHARM-2729      Adjusted logic for updating parent Trend Item LastModifiedDate.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Trend_Item_Trend_Bucket_AuditTrigger on Trend_Item_Trend_Bucket__c (before update,before delete,after insert,after update,after delete){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {

        if(Trigger.isInsert && Trigger.isBefore){
             // Place your code. 
        }
        /* After Insert */
        else if(Trigger.isInsert && Trigger.isAfter){
            // Def #123/CHARM-2729: skip parent Trend Item updating if it already updated in current transaction
            if(!UpdateParentUtility.isTrendItemUpdated){
                Set<Id> trendItemRecordIdSet = new Set<Id>();
                for(Trend_Item_Trend_Bucket__c trendItemCode : (List<Trend_Item_Trend_Bucket__c>)Trigger.new){
                    if (trendItemCode.Trend_Item__c != null) {
                        trendItemRecordIdSet.add(trendItemCode.Trend_Item__c);              
                    }
                }
                if (trendItemRecordIdSet.size() > 0) {
                    UpdateParentUtility.isTrendItemUpdated = true;
                    UpdateParentUtility.isTrendItemLastModifDateUpdating = true;
                    UpdateParentUtility.updateparent_trend(trendItemRecordIdSet);
                    UpdateParentUtility.isTrendItemLastModifDateUpdating = false;
                }
            }
            CMPL123.AuditHandler.handleAudit();
        }
        /* Before Update */
        else if(Trigger.isUpdate && Trigger.isBefore){

        }
        /* After Update */
        else if(Trigger.isUpdate && Trigger.isAfter){
            // Def #123/CHARM-2729: skip parent Trend Item updating if it already updated in current transaction
            if(!UpdateParentUtility.isTrendItemUpdated){
                Set<Id> trendItemRecordIdSet = new Set<Id>();
                for(Trend_Item_Trend_Bucket__c trendItemCode : (List<Trend_Item_Trend_Bucket__c>)Trigger.new){
                    if (trendItemCode.Trend_Item__c != null) {
                        trendItemRecordIdSet.add(trendItemCode.Trend_Item__c);              
                    }
                }
                if (trendItemRecordIdSet.size() > 0) {
                    UpdateParentUtility.isTrendItemUpdated = true;
                    UpdateParentUtility.isTrendItemLastModifDateUpdating = true;
                    UpdateParentUtility.updateparent_trend(trendItemRecordIdSet);
                    UpdateParentUtility.isTrendItemLastModifDateUpdating = false;
                }
            }    
            CMPL123.AuditHandler.handleAudit();
        }
        /* Before Delete */
        else if(Trigger.isDelete && Trigger.isBefore){
            CMPL123.AuditHandler.handleAudit();
        }
        /* After Delete */
        else if(Trigger.isDelete && Trigger.isAfter){
             // Place your code. 
        }
    }
}