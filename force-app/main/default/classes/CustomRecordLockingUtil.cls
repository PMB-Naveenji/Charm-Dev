/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : CustomRecordLockingUtil.
* @Why   : Public class to manage cases when record lock should enforced for all fields except specified.
* @When  : 17-DEC-19.
* @Where : From ADDHazardAssessmentTriggerHandler, ADDInvestigationHandler, ADDInvestigationTaskTriggerHandler
*           ADDRegulatoryAssessmentTriggerHandler, ADDTrendItemMaintainanceReqHandler, ADDTTReviewTaskTriggerhandler classes.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    17-DEC-19              Defect #1600                  Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                    Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                    Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                    Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    27-OCT-2020            HC #100/CHARM-3518            Added validateRecordEdit method.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    03-NOV-2020            HC #100/CHARM-3518            Adjusted validateRecordEdit method logic.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class CustomRecordLockingUtil {
    private static final List <String> packageAndSystemFieldsToDismiss = new List <String> {
        'LastModifiedBy', 'Last_Modified_Date_Time__c','LastModifiedDate', 'SystemModstamp', 'LastModifiedById',
        'CMPL123Rule_Key_Value__c', 'CMPL123Task_Key_Value__c',
        'CMPL123_WF_Action__c', 'CMPL123_WF_Action_Performed_By__c',
        'CMPL123_WF_Action_Performed_On__c', 'CMPL123_WF_Status__c'
    };

    /*
    * @Method       : validateRecordEdit.
    * @Description  : Validate record edit.
    * @Invoke       : From Apex classes.
    * @Return       : N/A.
    * @Params       : Map <Id, sObject> newRecords,
    *                   Map <Id, sObject> oldRecords,
    *                   List <String> lockedStatuses,
    *                   List <String> allowedPermissionSets,
    *                   List <String> allowedFieldsAPINames.
    */
    public static void validateRecordEdit(
            Map <Id, sObject> newRecords,
            Map <Id, sObject> oldRecords,
            List <String> lockedStatuses,
            List <String> allowedPermissionSets,
            List <String> allowedFieldsAPINames
    ) {
        ADD_App_Settings__c addAppSettings = ADD_App_Settings__c.getValues(UserInfo.getUserId());
        if (addAppSettings == null || (null != addAppSettings && !addAppSettings.Restrict_Validation_Rules__c)) {
            List <PermissionSetAssignment> currentUserPermissionSetAssignments = [
                    SELECT Id, PermissionSet.Name
                    FROM PermissionSetAssignment
                    WHERE AssigneeId = :UserInfo.getUserId()
            ];
            List <String> currentUserPermissionSetNames = new List <String> ();
            for (PermissionSetAssignment psa : currentUserPermissionSetAssignments) {
                currentUserPermissionSetNames.add(psa.PermissionSet.Name);
            }
            for (Id recordId : newRecords.keySet()) {
                sObject newRecord = newRecords.get(recordId);
                sObject oldRecord = oldRecords.get(recordId);
                if ((newRecord.get('CMPL123_WF_Status__c') == oldRecord.get('CMPL123_WF_Status__c'))
                        && lockedStatuses.contains((String) newRecord.get('CMPL123_WF_Status__c'))) {
                    Map <String, Object> newFieldsAndValuesMap = newRecord.getPopulatedFieldsAsMap();
                    Map <String, Object> oldFieldsAndValuesMap = oldRecord.getPopulatedFieldsAsMap();
                    List <String> newFieldsAndValuesMapKeys = new List <String> (newFieldsAndValuesMap.keySet());
                    List <String> oldFieldsAndValuesMapKeys = new List <String> (oldFieldsAndValuesMap.keySet());
                    newFieldsAndValuesMapKeys = validateRecordEditHelper(newFieldsAndValuesMapKeys, packageAndSystemFieldsToDismiss);
                    oldFieldsAndValuesMapKeys = validateRecordEditHelper(oldFieldsAndValuesMapKeys, packageAndSystemFieldsToDismiss);
                    List <String> fieldsWithEqualValues = new List <String> ();
                    for (String fieldToCompare : newFieldsAndValuesMap.keySet()) {
                        if (newFieldsAndValuesMap.get(fieldToCompare) == oldFieldsAndValuesMap.get(fieldToCompare)) {
                            fieldsWithEqualValues.add(fieldToCompare);
                        }
                    }
                    newFieldsAndValuesMapKeys = validateRecordEditHelper(newFieldsAndValuesMapKeys, fieldsWithEqualValues);
                    oldFieldsAndValuesMapKeys = validateRecordEditHelper(oldFieldsAndValuesMapKeys, fieldsWithEqualValues);
                    for (String permissionSetName : currentUserPermissionSetNames) {
                        if (allowedPermissionSets.contains(permissionSetName)) {
                            newFieldsAndValuesMapKeys = validateRecordEditHelper(newFieldsAndValuesMapKeys, allowedFieldsAPINames);
                            oldFieldsAndValuesMapKeys = validateRecordEditHelper(oldFieldsAndValuesMapKeys, allowedFieldsAPINames);
                            break;
                        }
                    }
                    if (newFieldsAndValuesMapKeys.size() > 0 || oldFieldsAndValuesMapKeys.size() > 0) {
                        newRecords.get(recordId).addError(System.label.Record_Locked);
                    }
                }
            }
        }
    }

    /*
    * @Method       : validateRecordEdit.
    * @Description  : Validate record edit.
    * @Invoke       : From Apex classes.
    * @Return       : N/A.
    * @Params       : Map <Id, sObject> newRecords,
    *                   Map <Id, sObject> oldRecords,
    *                   String wfStatusAPIName,
    *                   Set <String> lockedStatuses,
    *                   Set <String> allowedFieldsAPINames.
    */
    public static void validateRecordEdit(
            Map <Id, sObject> newRecords,
            Map <Id, sObject> oldRecords,
            String wfStatusAPIName,
            Set <String> lockedStatuses,
            Set <String> allowedFieldsAPINames
    ) {
        ADD_App_Settings__c addAppSettings = ADD_App_Settings__c.getValues(UserInfo.getUserId());
        if (addAppSettings == null || (null != addAppSettings && !addAppSettings.Restrict_Validation_Rules__c)) {
            for (Id recordId : newRecords.keySet()) {
                sObject newRecord = newRecords.get(recordId);
                sObject oldRecord = oldRecords.get(recordId);
                if ((newRecord.get(wfStatusAPIName) == oldRecord.get(wfStatusAPIName))
                        && lockedStatuses.contains((String) newRecord.get(wfStatusAPIName))) {
                    Map <String, Object> newFieldsAndValuesMap = newRecord.getPopulatedFieldsAsMap();
                    Map <String, Object> oldFieldsAndValuesMap = oldRecord.getPopulatedFieldsAsMap();
                    Set <String> newFieldsAndValuesMapKeys = newFieldsAndValuesMap.keySet();
                    Set <String> oldFieldsAndValuesMapKeys = oldFieldsAndValuesMap.keySet();
                    newFieldsAndValuesMapKeys.removeAll(allowedFieldsAPINames);
                    oldFieldsAndValuesMapKeys.removeAll(allowedFieldsAPINames);

                    List <String> fieldsWithEqualValues = new List <String> ();
                    for (String fieldToCompare : newFieldsAndValuesMapKeys) {
                        // Remove line breaks if the field could be the text area
                        if (newFieldsAndValuesMap.get(fieldToCompare) instanceof String
                                && oldFieldsAndValuesMap.get(fieldToCompare) instanceof String) {
                            if (((String)newFieldsAndValuesMap.get(fieldToCompare)).replaceAll('\r\n|\n|\r',' ') ==
                                            ((String)oldFieldsAndValuesMap.get(fieldToCompare)).replaceAll('\r\n|\n|\r',' ')) {
                                fieldsWithEqualValues.add(fieldToCompare);
                            }
                        } else if (newFieldsAndValuesMap.get(fieldToCompare) == oldFieldsAndValuesMap.get(fieldToCompare)) {
                            fieldsWithEqualValues.add(fieldToCompare);
                        }
                    }
                    newFieldsAndValuesMapKeys.removeAll(fieldsWithEqualValues);
                    oldFieldsAndValuesMapKeys.removeAll(fieldsWithEqualValues);

                    if (newFieldsAndValuesMapKeys.size() > 0 || oldFieldsAndValuesMapKeys.size() > 0) {
                        newRecords.get(recordId).addError(System.label.Record_Locked);
                    }
                }
            }
        }
    }

    /*
    * @Method       : validateRecordEditHelper
    * @Description  : Helper for validateRecordEdit method.
    * @Invoke       : From Apex classes.
    * @Return       : List<String>.
    * @Params       : List<String> fieldsListToClear, List<String> fieldsToRemove.
    */
    private static List<String> validateRecordEditHelper(List<String> fieldsListToClear, List<String> fieldsToRemove) {
        for (String fieldToRemove : fieldsToRemove) {
            Integer fieldIndex = fieldsListToClear.indexOf(fieldToRemove);
            if (fieldIndex >= 0) {
                fieldsListToClear.remove(fieldIndex);
            }
        }
        return fieldsListToClear;
    }
}