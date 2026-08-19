/**
 * -----------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : ADDTicketUpdateAsync.
 * @Why   : Handles the asynchronous update of Ticket from Product Ticket.
 * @When  : 06-APR-2017.
 * @Where : From ADDProductTicketTriggerHandler class.
 * -----------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * -----------------------------------------------------------------------------------------------------------------------------------
 * Developer              Date                      Modification ID              Description
 * -----------------------------------------------------------------------------------------------------------------------------------
 * Admin                  06-APR-2017               Work ID / Case ID            Created.
 * -----------------------------------------------------------------------------------------------------------------------------------
 * RSlob                  10-DEC-2019               Defect #1439                 Modified.
 * -----------------------------------------------------------------------------------------------------------------------------------
 * dskak                  06-APR-2020               Defect #54                   Modified.
 * -----------------------------------------------------------------------------------------------------------------------------------
 * dskak                  15-APR-2020               Defect #71                   Modified.
 * -----------------------------------------------------------------------------------------------------------------------------------
 * dskak                  16-APR-2020               Defect #71                   Modified.
 * -----------------------------------------------------------------------------------------------------------------------------------
 * dskak                  18-JUN-2020               #115.1/CHARM-2832            Modified.
 * -----------------------------------------------------------------------------------------------------------------------------------
 * rsitc                  05-OCT-2020               #3/CHARM-3221                Added null checking condition.
 * -----------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik           07-OCT-2022               CHaRM R2.2, IPDR 66          Can now set the list of Product Names, List #s, and Lot #s
 * to a message stating that there are too many entries to fit in the field. Code cleanup
 * -----------------------------------------------------------------------------------------------------------------------------------
 */

global class ADDTicketUpdateAsync {
    /**
     * @Method       : ticketUpdateAsync.
     * @Description  : To update Ticket data from Product Ticket record asynchronously.
     * @Invoke       : From ADDProductTicketTriggerHandler class.
     * @Return       : N/A.
     * @Params       : Set<Id> recordIds, Boolean isInsert.
     * @Revision     : 07-OCT-2022 Larry: Batch_Lot_Serial__c, Product_Name__c, Product_Ticket_List_Number__c
     * are set to CumulativeFieldTooLong if their strings are too long. Added constants. Code cleanup.
     */
    @future
    public static void ticketUpdateAsync(Set<Id> recordIds, Boolean isInsert) {
        final String NEWLINE = '\r\n';
        final String COMMA_NEWLINE = ',\r\n';
        Map<String, SObjectField> fields =
            SObjectType.CMPL123CME__Complaint__c.fields.getMap();
        final Integer PRODUCT_NAME_LEN = fields.get('Product_Name__c').getDescribe().getLength();
        final Integer LOT_NUM_LEN = fields.get('Batch_Lot_Serial__c').getDescribe().getLength();
        final Integer LIST_NUM_LEN = fields.get('Product_Ticket_List_Number__c').getDescribe().getLength();

        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        Set<Id> complaintIds = new Set<Id>();
        Map<Id, CMPL123CME__Complaint__c> updatableComplaints = new Map<Id, CMPL123CME__Complaint__c>();

        List<Product_Ticket__c> productTickets = [
                SELECT Id, Name, Event_Ticket__c, Likely_Cause__c, Product_Name__c, Product_List_Number__c, Batch_Lot_Serial__c,
                        Product__r.Instrument_Name__c, Product__r.CMPL123__Product_Family__c,
                        Product__r.List_Number__c, Product__r.Product_Description__c
                FROM Product_Ticket__c
                WHERE Id IN :recordIds
                ORDER BY Name DESC
        ];

        for (Product_Ticket__c pt : productTickets) {
            // Defect #3/CHARM-3221 fix: added null checking condition
            if (pt.Event_Ticket__c != null) {
                complaintIds.add(pt.Event_Ticket__c);
            }
        }

        Map<Id, CMPL123CME__Complaint__c> complaintsMap = new Map<Id, CMPL123CME__Complaint__c>(
        [
                SELECT Product_Instrument_Name__c, Product_Family__c, Product_Ticket_Added__c, Product_Description__c, Batch_Lot_Serial__c,
                    Likely_Cause__c, Product_Name__c, Product_Ticket_List_Number__c,
                    (SELECT Name, Batch_Lot_Serial__c, Product_List_Number__c, Product_Name__c, Likely_Cause__c, Product__r.List_Number__c FROM Products_Events__r)
                FROM CMPL123CME__Complaint__c
                WHERE Id IN :complaintIds
        ]);

        //Defect #1439 fix BEGIN
        for (Id cmplId : complaintIds) {
            CMPL123CME__Complaint__c updatableComplaint = complaintsMap.get(cmplId);
            updatableComplaint.Product_Name__c = '';
            updatableComplaint.Product_Ticket_List_Number__c = '';
            updatableComplaint.Product_Instrument_Name__c = null;
            updatableComplaint.Product_Family__c = null;
            updatableComplaint.Product_Description__c = null;
            updatableComplaint.Batch_Lot_Serial__c = null;
            updatableComplaint.Likely_Cause__c = null;
        }
        //Defect #1439 fix END

        for (Product_Ticket__c pt : productTickets) {
            if (pt.Event_Ticket__c == null) {
                continue;
            }
            CMPL123CME__Complaint__c updatableComplaint = complaintsMap.get(pt.Event_Ticket__c);

            if (pt.Product__r.Instrument_Name__c != null) {
                updatableComplaint.Product_Instrument_Name__c = updatableComplaint.Product_Instrument_Name__c != null
                        ? updatableComplaint.Product_Instrument_Name__c + NEWLINE + pt.Product__r.Instrument_Name__c
                        : pt.Product__r.Instrument_Name__c;
            }

            if (pt.Product__r.CMPL123__Product_Family__c != null) {
                updatableComplaint.Product_Family__c = updatableComplaint.Product_Family__c != null
                        ? updatableComplaint.Product_Family__c + NEWLINE + pt.Product__r.CMPL123__Product_Family__c
                        : pt.Product__r.CMPL123__Product_Family__c;
            }

            if (pt.Product__r.Product_Description__c != null) {
                updatableComplaint.Product_Description__c = updatableComplaint.Product_Description__c != null
                        ? updatableComplaint.Product_Description__c + NEWLINE + pt.Product__r.Product_Description__c
                        : pt.Product__r.Product_Description__c;
            }

            if (pt.Batch_Lot_Serial__c != null) {
                updatableComplaint.Batch_Lot_Serial__c = updatableComplaint.Batch_Lot_Serial__c != null
                        ? updatableComplaint.Batch_Lot_Serial__c + NEWLINE + pt.Batch_Lot_Serial__c
                        : pt.Batch_Lot_Serial__c;
                system.debug('Batch Lot Serial ::::::::::::::::::::::::::::: '+pt.Batch_Lot_Serial__c+ ' ::::::::::::::::::::::::: Complaint ::::::::::::::::::; '+updatableComplaint.Batch_Lot_Serial__c);
            }

            if (pt.Likely_Cause__c != null) {
                updatableComplaint.Likely_Cause__c = updatableComplaint.Likely_Cause__c != null
                        ? updatableComplaint.Likely_Cause__c + NEWLINE + pt.Likely_Cause__c
                        : pt.Likely_Cause__c;
            }

            updatableComplaints.put(updatableComplaint.Id, updatableComplaint);
        }

        //  Defect #54 fix start
        for (CMPL123CME__Complaint__c complaint :complaintsMap.values()) {
            CMPL123CME__Complaint__c updatableComplaint = updatableComplaints.get(complaint.Id);

            //  Defect #115.1 / CHARM-2832 fix start
            //added for defect 368
            String productTicketAdded = '';

            for (Product_Ticket__c pt :complaint.Products_Events__r) {
                updatableComplaint.Product_Name__c += pt.Product_Name__c + COMMA_NEWLINE;
                updatableComplaint.Product_Ticket_List_Number__c += pt.Product__r.List_Number__c != null
                    ? pt.Product__r.List_Number__c + COMMA_NEWLINE
                    : '';

                //Defect #1439 fix BEGIN
                String ptAsString = '';

                if (String.isNotBlank(pt.Name)) {
                    ptAsString += 'Product-Ticket: ' + pt.Name + COMMA_NEWLINE;
                }

                if (String.isNotBlank(pt.Product_Name__c)) {
                    ptAsString += 'Product: ' + pt.Product_Name__c + COMMA_NEWLINE;
                }

                if (String.isNotBlank(pt.Product_List_Number__c)) {
                    ptAsString += 'List No: ' + pt.Product_List_Number__c + COMMA_NEWLINE;
                }

                if (String.isNotBlank(pt.Batch_Lot_Serial__c)) {
                    ptAsString += 'Batch Lot: ' + pt.Batch_Lot_Serial__c + COMMA_NEWLINE;
                }

                ptAsString += 'Likely Cause: ' + (String.isNotBlank(pt.Likely_Cause__c) ? pt.Likely_Cause__c : '--None--');

                if (String.isNotBlank(ptAsString)) {
                    ptAsString = ptAsString.removeEnd(COMMA_NEWLINE);
                    productTicketAdded += String.isNotBlank(productTicketAdded) ? NEWLINE + NEWLINE : '';
                    productTicketAdded += ptAsString;
                }
                //Defect #1439 fix END

                updatableComplaint.Product_Ticket_Added__c = productTicketAdded;
                updatableComplaints.put(updatableComplaint.Id, updatableComplaint);
            }

            updatableComplaint.Product_Ticket_Added__c = productTicketAdded;
            system.debug('Product Ticket :::::::::::::::::::::: '+updatableComplaint.Product_Ticket_Added__c);
            //  Defect #115.1 / CHARM-2832 fix end

            if (updatableComplaint.Batch_Lot_Serial__c != null &&
                updatableComplaint.Batch_Lot_Serial__c.length() > LOT_NUM_LEN
            ) {
                updatableComplaint.Batch_Lot_Serial__c = System.label.CumulativeFieldTooLong;
            }

            updatableComplaint.Product_Name__c =
                updatableComplaint.Product_Name__c
                .removeEnd(COMMA_NEWLINE);
            if (updatableComplaint.Product_Name__c.length() > PRODUCT_NAME_LEN) {
                updatableComplaint.Product_Name__c = System.label.CumulativeFieldTooLong;
            }

            //  Defect #71 fix start
            updatableComplaint.Product_Ticket_List_Number__c = 
                updatableComplaint.Product_Ticket_List_Number__c
                .removeEnd(COMMA_NEWLINE);
            if (updatableComplaint.Product_Ticket_List_Number__c.length() > LIST_NUM_LEN) {
                updatableComplaint.Product_Ticket_List_Number__c = System.label.CumulativeFieldTooLong;
            }
            //  Defect #71 fix end
        }
        //  Defect #54 fix end

        if (!updatableComplaints.isEmpty()) {
            update updatableComplaints.values();
        }
    }
}