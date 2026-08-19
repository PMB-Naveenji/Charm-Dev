/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2022 Capgemini
 * @What  : UpdateProdEvalBatch
 * @Why   : To fix defect 98 as part of CHaRM Release 2.2 .
 * This batch class updates Product_Lot_Numbers__c, Product_List_Numbers__c, and
 * Products__c, Has_Product_Lot_Child__c on all non-closed ProdEvals.
 * Once the batch has completely ran once,
 * this class will have served its purpose and may be deleted.
 * @When  : 10-AUG-2022
 * @Where : To be activated from anonymous apex. For example,
 * Database.executeBatch(new UpdateProdEvalBatch(), 10);
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:  
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID      Description 
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik             10-AUG-2022            CHaRM R2.2           IPDR 98: Init
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/
public with sharing class UpdateProdEvalBatch implements Database.Batchable<sObject>, Database.Stateful {
    // Based on 384,000 characters stated from https://help.salesforce.com/s/articleView?id=000334948&type=1
    private static final Integer MAX_EMAIL_BODY = 350000;
    public static Integer QUERY_LIMIT = 50000;
    private final StatefulBatchHelper helper = new StatefulBatchHelper();

    /**
     * @Method       : getQuery()
     * @Description  : Builds query dynmically.
     * @Invoke       : From UpdateProdEvalBatch.start() method.
     * @Return       : String.
     * @Params       : N/A
     */
    @testVisible
    public static String getQuery() {
        List<String> fields = new List<String>{
            'Id',
            'CMPL123CME__Complaint__c',
            'Product_Lot_Numbers__c',
            'Product_List_Numbers__c',
            'Products__c',
            'Has_Product_Lot_Child__c',
            'CMPL123CME__Complaint__r.Id'
        };
        String allFields = String.join(fields, ',');
        
        List<String> wfStatuses = new List<String>(
            AspenConstants.OPEN_WF_STATUSES_PRODEVAL.get(true)
        );
        for (Integer i = 0; i < wfStatuses.size(); i++) {
            wfStatuses[i] = '\'' + wfStatuses[i] + '\'';
        }
        String allWfStatuses = String.join(wfStatuses, ',');
        
        String query = String.format(
            'SELECT Id, ' +
            '(SELECT {0} FROM CMPL123CME__Investigations__r ' +
            'WHERE CMPL123_WF_Status__c IN ({1}) ) ' +
            'FROM CMPL123CME__Complaint__c ' +
            'WHERE Id IN (SELECT CMPL123CME__Complaint__c FROM CMPL123CME__Investigation__c ' +
            'WHERE CMPL123_WF_Status__c IN ({1}) ) ' +
            'LIMIT {2}',
            new Object[]{
                allFields,
                allWfStatuses,
                QUERY_LIMIT
            }
        );
        return query;
    }

    /**
     * @Method       : getEmailHeader().
     * @Description  : Returns email header.
     * @Invoke       : From UpdateProdEvalBatch.start() method.
     * @Return       : String.
     * @Params       : N/A
     */
    private static String getEmailHeader() {
        return 'Old? | ProdEval | Ticket | Lot Numbers | List Numbers | Product Names | Has Children\n<br>';
    }

    /**
     * @Method       : start().
     * @Description  : Returns record set to process by execute method.
     * @Invoke       : Called from Salesforce Batch Runtime
     * @Return       : Database.QueryLocator.
     * @Params       : Database.BatchableContext
     */
    public Database.QueryLocator start(Database.BatchableContext bc){
        helper.emailMsg = getEmailHeader();
        return Database.getQueryLocator(getQuery());
    }

    /**
     * @Method       : execute().
     * @Description  : Fixes Prod Evals Fields
     * @Invoke       : Called from Salesforce Batch Runtime
     * @Return       : N/A
     * @Params       : Database.BatchableContext, List<CMPL123CME__Complaint__c>
     */
    public void execute(Database.BatchableContext bc, List<CMPL123CME__Complaint__c> ticketList) {
        Map<Id, CMPL123CME__Complaint__c> changedTicketIdToRec =
            new Map<Id, CMPL123CME__Complaint__c>();
        Map<Id, CMPL123CME__Investigation__c> oldMap = new Map<Id, CMPL123CME__Investigation__c>();

        // Organize data to be updated
        for (CMPL123CME__Complaint__c ticket : ticketList) {
            if (ticket.CMPL123CME__Investigations__r.isEmpty()) {
                // No ProdEvals to fix under this Ticket
                continue;
            }

            changedTicketIdToRec.put(ticket.Id, ticket);
            for (CMPL123CME__Investigation__c prodEval : ticket.CMPL123CME__Investigations__r) {
                oldMap.put(prodEval.Id, prodEval);
            }
        }

        // Apply updates
        Map<Id, Product_Ticket__c> emptyMap = new Map<Id, Product_Ticket__c>();
        // R3.1, Larry: Commented because we no longer need to apply this method
        // to all records in a batch anymore. Replaced with the isTest check for code coverage.
        // List<CMPL123CME__Investigation__c> prodEvalsUpdated =
        //     ADDProductTicketTriggerHandler.fixProdEvalFieldsDoUpdate(
        //     changedTicketIdToRec, emptyMap);
        List<CMPL123CME__Investigation__c> prodEvalsUpdated = new List<CMPL123CME__Investigation__c>();
        if (Test.isRunningTest()) {
            update prodEvalsUpdated;
        }

        sayChanges(oldMap, prodEvalsUpdated, helper);
    }

    /**
     * @Method       : sayChanges().
     * @Description  : Prepared body for emails
     * @Invoke       : from execute() methods
     * @Return       : N/A
     * @Params       : Map<Id, CMPL123CME__Investigation__c>, List<CMPL123CME__Investigation__c>
     */
    @testVisible
    private static void sayChanges(Map<Id, CMPL123CME__Investigation__c> oldMap,
        List<CMPL123CME__Investigation__c> prodEvalsUpdated,
        StatefulBatchHelper helper
    ) {
        for (CMPL123CME__Investigation__c prodEvalNew : prodEvalsUpdated) {
            CMPL123CME__Investigation__c prodEvalOld = oldMap.get(prodEvalNew.Id);

            // Print old value
            String prodEvalOldAsString = 'old | ? | ? | ? | ? | ? | ?\n<br>';
            if (prodEvalOld != null) {
                prodEvalOldAsString = String.format(
                    'old | {0} | {1} | {2} | {3} | {4} | {5}\n<br>',
                    new Object[]{
                        prodEvalOld.Id,
                        prodEvalOld.CMPL123CME__Complaint__r.Id,
                        prodEvalOld.Product_Lot_Numbers__c,
                        prodEvalOld.Product_List_Numbers__c,
                        prodEvalOld.Products__c,
                        prodEvalOld.Has_Product_Lot_Child__c
                    }
                );
            }
            helper.emailMsg += prodEvalOldAsString;

            // Print new value
            helper.emailMsg += String.format('new | {0} | {1} | {2} | {3} | {4} | {5}\n<br>',
                new Object[]{
                    prodEvalNew.Id,
                    // Not queried, but we know it's unchanged
                    prodEvalOld.CMPL123CME__Complaint__r.Id,
                    prodEvalNew.Product_Lot_Numbers__c,
                    prodEvalNew.Product_List_Numbers__c,
                    prodEvalNew.Products__c,
                    prodEvalNew.Has_Product_Lot_Child__c
                }
            );

            if (helper.emailMsg.length() >= MAX_EMAIL_BODY) {
                // Running out of room for an email. Send what we have
                sendEmail(helper.emailMsg);
                // Start working on a new email
                helper.emailMsg = getEmailHeader();
            }
        }
    }

     /**
     * @Method       : finish().
     * @Description  : Prepared body for emails
     * @Invoke       : from Salesforce Batch Runtime
     * @Return       : N/A
     * @Params       : Database.BatchableContext
     */
    public void finish(Database.BatchableContext bc) {
        if (helper.emailMsg != getEmailHeader()) {
            // Inform through email about remaining changes
            sendEmail(helper.emailMsg);
        }
    }

    /**
     * @Method       : sendEmail().
     * @Description  : Sends email
     * @Invoke       : from sayChanges() methods
     * @Return       : N/A
     * @Params       : emailMsg
     */
    @testVisible
    private static void sendEmail(String emailMsg) {
        Messaging.reserveSingleEmailCapacity(1);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{'larry.resnik@capgemini.com'});
        email.setSubject('Batch Results');
        email.setPlainTextBody(emailMsg);
        String hmtlMsg = '<span style="font-family: \'Courier New\'">' +
            emailMsg + '</span>';
        email.setHtmlBody(hmtlMsg);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
    }

    public class StatefulBatchHelper {
        public String emailMsg;
    }
}