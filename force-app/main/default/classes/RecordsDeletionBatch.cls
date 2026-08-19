/*
* Created by DSkak on 9/16/2020 to remove old records by Abbott request.
*
* Objects to delete: 'Product_Ticket__c', 'Task__c', 'CMPL123CME__Investigation__c', 'Medical_Evaluation_Task__c',
*	'CMPL123CME__Questionnaire_Items__c', 'Reportability_History__c', 'CMPL123CME__Questionnaire__c', 'pRE_Question__c',
*	'pRE_Information__c', 'Search_Log__c', 'Ticket_Search_Result__c', 'Search__c', 'Ticket_Review__c', 'Translation_Item__c',
*	'Translation_Task__c', 'Ticket_Note__c', 'Error_Log__c', 'CMPL123CME__Complaint__c', 'Attachment__c'.
*/

global class RecordsDeletionBatch implements Database.Batchable<sObject>, Database.Stateful {
    global List<String> ObjectsAPINames;
    global final String Query;

    global RecordsDeletionBatch (List <String> objectsAPINamesList) {
        ObjectsAPINames = objectsAPINamesList;
        Query = 'SELECT Id FROM ' + String.escapeSingleQuotes(ObjectsAPINames.get(0)) + ' WHERE CreatedDate <= 2020-08-31T00:00:00Z';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(Query);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        delete scope;
    }

    global void finish(Database.BatchableContext bc) {
        if (ObjectsAPINames != null && ObjectsAPINames.size() > 0) {
            ObjectsAPINames.remove(0);
            Database.executeBatch(new RecordsDeletionBatch(ObjectsAPINames));
        }
    }
}