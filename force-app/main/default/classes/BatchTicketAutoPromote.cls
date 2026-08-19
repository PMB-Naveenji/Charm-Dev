/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : BatchTicketAutoPromote.
* @Why   : Handle the Tickets which wasn't auto promoted earlier.
* @When  : 06-APR-2017.
* @Where : From ProcessMigratedRecords.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    06-APR-2017             Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020             Code Audit                Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020             Code Audit                Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* OOber                    16-JUN-2020             #101.1/CHARM-2884         Removed hardcoded emails.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                    19-AUG-2020             Code Audit                Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class BatchTicketAutoPromote implements Database.Batchable<sObject>, Database.Stateful {

    global Map<String, String> inputTickets = new Map<String, String>();
    global Map<String, String> processedTickets = new Map<String, String>();
    global Map<String, String> erroredTickets = new Map<String, String>();
    global Map<String, String> skippedTickets = new Map<String, String>();

    /*
    * @Method       : Constructor.
    * @Description  : To initialize default parameters.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public BatchTicketAutoPromote() {
    }

    /*
    * @Method       : start.
    * @Description  : To identify the records to be processed for Auto Promotion.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC.
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Ready_to_Close__c, CMSNext__c, Division__c, MDC_All_ACKs_Received__c, CMPL123Task_Key_Value__c, CMPL123CME__CMPL123_WF_Status__c, CMSNext_Ticket_Number__c, ' +
                            '(SELECT Id FROM CMPL123CME__Investigations__r WHERE CMPL123_WF_Status__c != \'Closed-Voided\' AND CMPL123_WF_Status__c != \'Closed-Done\' LIMIT 1), ' +
                            '(SELECT Id FROM Customer_Responses__r WHERE CMPL123_WF_Status__c != \'Closed-Voided\' AND CMPL123_WF_Status__c != \'Closed-Done\' LIMIT 1), ' +
                            '(SELECT Id FROM Returns__r WHERE CMPL123_WF_Status__c != \'Closed-Done\' AND CMPL123_WF_Status__c != \'Closed-Voided\' LIMIT 1), ' +
                            '(SELECT Id FROM Evaluation_Investigation_Tasks__r WHERE CMPL123_WF_Status__c != \'Closed-Done\' AND CMPL123_WF_Status__c != \'Closed-Voided\' LIMIT 1), ' +
                            '(SELECT Id FROM Meaningful_Data_Requests__r WHERE Request_Status__c != \'Completed\' AND Request_Status__c != \'Voided\' LIMIT 1), ' +
                            '(SELECT Id FROM Translation_Tasks__r WHERE CMPL123_WF_Status__c != \'Closed-Done\' AND CMPL123_WF_Status__c != \'Closed-Voided\' LIMIT 1), ' +
                            '(SELECT Id FROM CMPL123CME__Questionnaires__r WHERE CMPL123_WF_Status__c != \'Closed-Done\' AND CMPL123_WF_Status__c != \'Closed-Voided\' LIMIT 1) ' +
                            'FROM CMPL123CME__Complaint__c WHERE Ticket_Type__c = \'Complaint\' AND CMPL123CME__CMPL123_WF_Status__c != \'Closed-Done\' AND CMPL123CME__CMPL123_WF_Status__c != \'Closed-Voided\' AND MDC_All_ACKs_Received__c = true AND SystemModstamp >= YESTERDAY';

        return Database.getQueryLocator(query);
    }

    /*
    * @Method       : execute.
    * @Description  : To execute Auto Promotion process of Ticket records.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC, List<SObject> lstRecords.
    */
    global void execute(Database.BatchableContext BC, List<SObject> lstRecords) {
        List<CMPL123CME__Complaint__c> ticketList = new List<CMPL123CME__Complaint__c>();

        for(CMPL123CME__Complaint__c ticket: (List<CMPL123CME__Complaint__c>)lstRecords) {
            inputTickets.put(ticket.CMSNext_Ticket_Number__c, ticket.CMPL123CME__CMPL123_WF_Status__c);

            if (ticket.MDC_All_ACKs_Received__c &&
                ticket.CMPL123CME__Investigations__r.size() == 0 &&
                ticket.Evaluation_Investigation_Tasks__r.size() == 0 &&
                ticket.Customer_responses__r.size() == 0 &&
                ticket.Returns__r.size() == 0 &&
                ticket.Meaningful_Data_Requests__r.size() == 0 &&
                ticket.Translation_Tasks__r.size() == 0) {
                if(ticket.CMPL123CME__CMPL123_WF_Status__c == 'Opened') {
                    ticket.Ready_to_Close__c = 'Yes';
                    ticket.CMPL123Task_Key_Value__c = 'ComplaintComplete';
                    ticketList.add(ticket);
                } else if(ticket.CMPL123CME__CMPL123_WF_Status__c == 'Complaint Complete' && ticket.CMSNext__c == 'Closed') {
                    ticket.CMPL123Task_Key_Value__c = 'FurtherRequired';
                    ticketList.add(ticket);
                } else if(ticket.CMPL123CME__Questionnaires__r.size() == 0) {
                    if(ticket.CMPL123CME__CMPL123_WF_Status__c == 'Registration Closed') {
                        ticket.CMPL123Task_Key_Value__c = 'complaintrcfr';
                        ticket.Ready_to_Close__c = '';
                        ticketList.add(ticket);
                    } else if(ticket.CMPL123CME__CMPL123_WF_Status__c == 'Final Review In Progress' && ticket.Division__c == 'ADD') {
                        ticket.CMPL123Task_Key_Value__c = 'addautofra';
                        ticketList.add(ticket);
                    } else {
                        skippedTickets.put(ticket.CMSNext_Ticket_Number__c, 'THIS IS NOT VALID STATUS [VERY VERY BAD] ' + ticket.CMPL123CME__CMPL123_WF_Status__c);
                    }
                } else {
                    skippedTickets.put(ticket.CMSNext_Ticket_Number__c, 'Pending +Assessment(s).');
                }
            } else if(ticket.CMPL123CME__CMPL123_WF_Status__c == 'Opened' && ticket.Ready_to_Close__c == 'Yes') {
                ticket.Ready_to_Close__c = 'No';
                ticketList.add(ticket);
            } else {
                String reason = 'Pending ';
                if(!ticket.MDC_All_ACKs_Received__c) { reason += '+MDC'; }
                if(ticket.CMPL123CME__Investigations__r.size() > 0) { reason += '+ProdEval(s)'; }
                if(ticket.Evaluation_Investigation_Tasks__r.size() > 0) { reason += '+ProdEval Task(s)'; }
                if(ticket.Returns__r.size() > 0) { reason += '+Customer Response(s)'; }
                if(ticket.Meaningful_Data_Requests__r.size() > 0) { reason += '+Meaningful Data Request(s)'; }
                if(ticket.Translation_Tasks__r.size() > 0) { reason += '+Translation Task(s)'; }
                if(ticket.CMPL123CME__Questionnaires__r.size() > 0) { reason += '+Assessment(s)'; }

                skippedTickets.put(ticket.CMSNext_Ticket_Number__c, reason);
            }
        }

        integer ticketIndex = 0;
        String errMessage = '';
        List<Error_Log__c> errList = new List<Error_Log__c>();

        for (Database.SaveResult sr : Database.update(ticketList, false)) {
            errMessage = '';
            if(sr.success) {
                processedTickets.put(ticketList[ticketIndex].CMSNext_Ticket_Number__c, ticketList[ticketIndex].CMPL123Task_Key_Value__c + ':' + ticketList[ticketIndex].Ready_to_Close__c);
            } else {
                for(Database.Error err : sr.getErrors()) {
                    errMessage += err.getMessage();
                }
                errList.add(ErrorLogFormatter.GetFormattedError(
                        ticketList[ticketIndex].CMSNext_Ticket_Number__c,
                        'Batch Ticket Auto Promotion Failed',
                        errMessage,
                        JSON.serialize(ticketList[ticketIndex])
                ));
                erroredTickets.put(ticketList[ticketIndex].CMSNext_Ticket_Number__c, errMessage);
            }
            ticketIndex++;
        }

        if(errList.size() > 0) {
            insert errList;
        }
    }

    /*
    * @Method       : finish.
    * @Description  : To send an email message when Auto Promotion process was finished.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC.
    */
    global void finish(Database.BatchableContext BC){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('BatchTicketAutoPromote Status on ' + System.now());
        String body = 'Summary of the processing happened for Auto Promotion <br/>';
        if(inputTickets.size() > 0) {
            body += '<br/> Total # of tickets processed were ' + inputTickets.size();
        }

        if(processedTickets.size() > 0 || erroredTickets.size() > 0 || skippedTickets.size() > 0) {
            body += '<br/><br/> Refer the below list of the CMSNext Ticket details';
            body += '<br/>     ' + processedTickets.size() + ' records processing were completed successfully.';
            for(String cmsnextTicket: processedTickets.keySet()) {
                body += '<br/>     ' + cmsnextTicket + '[SUCCESS]   - ' + inputTickets.get(cmsnextTicket) + '[STATUS] - ' + processedTickets.get(cmsnextTicket) + '.';
            }

            body += '<br/><br/>     ' + erroredTickets.size() + ' records processing were errored.';
            for(String cmsnextTicket: erroredTickets.keySet()) {
                body += '<br/>     ' + cmsnextTicket + '[FAILED]    - ' + inputTickets.get(cmsnextTicket) + '[STATUS] - ' + erroredTickets.get(cmsnextTicket) + '.';
            }

            body += '<br/><br/>     ' + skippedTickets.size() + ' records processing were skipped.';
            for(String cmsnextTicket: skippedTickets.keySet()) {
                body += '<br/>     ' + cmsnextTicket + '[SKIPPED]   - ' + inputTickets.get(cmsnextTicket) + '[STATUS] - ' + skippedTickets.get(cmsnextTicket) + '.';
            }
        } else {
            body += '<br/><br/> No Tickets processing happened.';
        }

        body += '<br/> <br/> Thanks';

        mail.setHtmlBody(body);

        mails.add(mail);
    }
}