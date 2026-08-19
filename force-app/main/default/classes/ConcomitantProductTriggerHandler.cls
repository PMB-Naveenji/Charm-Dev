/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ConcomitantProductTriggerHandler.
* @Why   : Public class to manage all the custom coding invoked on the CMPL123CME__Concomitant_Product__c object.
* @When  : 26-NOV-2018.
* @Where : From ConcomitantProductTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 26-NOV-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 21-AUG-2020            Code Audit                      Updated class comments. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* Lakshman                 03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D11_Concomitant_Null__c to CMPL123CME__D10_Concomitant_Product_Null__c
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
public class ConcomitantProductTriggerHandler {
    /*
    * @Method       : beforeInsertEventhandler.
    * @Description  : Before insert event handler.
    * @Invoke       : From ConcomitantProductTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void beforeInsertEventhandler () {
        //Added for W-000113
        validateProductTicketValues();
    }

    /*
    * @Method       : beforeUpdateEventhandler.
    * @Description  : Before update event handler.
    * @Invoke       : From ConcomitantProductTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void beforeUpdateEventhandler () {
        //Added for W-000113
        validateProductTicketValues();
    }

    /*
    * @Method       : afterInsertEventHandler.
    * @Description  : After insert event handler.
    * @Invoke       : From ConcomitantProductTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void afterInsertEventHandler () {
        //Map to hold EMDR records to be updated
        Map<Id,CMPL123CME__EMDR__c> mapEMDR = new Map<Id,CMPL123CME__EMDR__c>();
        for(CMPL123CME__Concomitant_Product__c objConProd : (List<CMPL123CME__Concomitant_Product__c>) Trigger.new){
            if(objConProd.CMPL123CME__Related_EMDR__c != null){
                mapEMDR.put(objConProd.CMPL123CME__Related_EMDR__c,
                            new CMPL123CME__EMDR__c(Id = objConProd.CMPL123CME__Related_EMDR__c, 
                                                    CMPL123CME__D10_Concomitant_Product_Null__c = ''));
            }
        }

        //Check if Map contains Records
        if(!mapEMDR.isEmpty()){
            update mapEMDR.values();
        }
    }

    /*
    * @Method       : afterDeleteEventHandler.
    * @Description  : After delete event handler.
    * @Invoke       : From ConcomitantProductTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void afterDeleteEventHandler() {
        //Set to hold EMDR record id
        Set <Id> objEMDRSet = new Set<Id> ();
        
        //Map to hold EMDR records to be updated
        Map <Id,CMPL123CME__EMDR__c> mapEMDR = new Map <Id,CMPL123CME__EMDR__c> ();
        for (CMPL123CME__Concomitant_Product__c objConProd : (List<CMPL123CME__Concomitant_Product__c>) Trigger.old){
            if(objConProd.CMPL123CME__Related_EMDR__c != null){
                objEMDRSet.add(objConProd.CMPL123CME__Related_EMDR__c);
            }
        }

        for (CMPL123CME__EMDR__c objEMDR : 
             [SELECT Id, 
                     (SELECT Id 
                      FROM CMPL123CME__Concommitant_Products__r 
                      LIMIT 1) 
              FROM CMPL123CME__EMDR__c 
              WHERE Id 
              IN :objEMDRSet]) {
            if (objEMDR.CMPL123CME__Concommitant_Products__r.size() == 0) {
                mapEMDR.put(objEMDR.Id, new CMPL123CME__EMDR__c(Id = objEMDR.Id, CMPL123CME__D10_Concomitant_Product_Null__c = 'NI'));

            }
        }

        //Check if Map contains Records
        if (!mapEMDR.isEmpty()) {
            Update mapEMDR.values();
        }
    }

    /*
    * @Method       : validateProductTicketValues.
    * @Description  : Added to implement W-000113: Add a lookup to Product - Ticket (display only Product - Ticket related to the parent Ticket.
    * @Invoke       : From beforeInsertEventhandler and beforeUpdateEventhandler methods of this class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private static void validateProductTicketValues(){
        Map <Id, Set<Id>> mapEMDRProductTicketIds = new Map <Id, Set<Id>> ();
        for (CMPL123CME__Concomitant_Product__c objConcomitantProduct : (List<CMPL123CME__Concomitant_Product__c>) Trigger.new){
            if (objConcomitantProduct.CMPL123CME__Related_EMDR__c != null 
                && objConcomitantProduct.Related_EMDR_Ticket__c != null 
                && objConcomitantProduct.Product_Ticket__c != null) {
                if (!mapEMDRProductTicketIds.containsKey(objConcomitantProduct.Related_EMDR_Ticket__c)) {
                    mapEMDRProductTicketIds.put(objConcomitantProduct.Related_EMDR_Ticket__c, 
                                                new Set <Id> {objConcomitantProduct.Product_Ticket__c});
                } else {
                    mapEMDRProductTicketIds.get(objConcomitantProduct.Related_EMDR_Ticket__c)
                                           .add(objConcomitantProduct.Product_Ticket__c);
                }
            }
        }

        Map <Id, Set<Id>> mapTicketProductTicketIds = new Map <Id, Set<Id>> ();
        Map <Id, Set<String>> mapProductTicketIdNames = new Map <Id, Set<String>> ();
        Map <Id, Product_Ticket__c> mapProductTickets = new Map <Id, Product_Ticket__c> ();
        if (!mapEMDRProductTicketIds.isEmpty()) {
            for (Product_Ticket__c objProductTicket
                : [SELECT Id, Name, Event_Ticket__c, Product_Name__c, Product_List_Number__c, Batch_Lot_Serial__c
                   FROM Product_Ticket__c 
                   WHERE Event_Ticket__c 
                   IN: mapEMDRProductTicketIds.keySet() 
                   ORDER BY Event_Ticket__c]) {
                if (!mapTicketProductTicketIds.containsKey(objProductTicket.Event_Ticket__c)) {
                    mapTicketProductTicketIds.put(objProductTicket.Event_Ticket__c, new Set<Id> {objProductTicket.Id});
                    mapProductTicketIdNames.put(objProductTicket.Event_Ticket__c, new Set<String> {objProductTicket.Name});
                } else {
                    mapTicketProductTicketIds.get(objProductTicket.Event_Ticket__c).add(objProductTicket.Id);
                    mapProductTicketIdNames.get(objProductTicket.Event_Ticket__c).add(objProductTicket.Name);
                }
                mapProductTickets.put(objProductTicket.Id,objProductTicket);
            }

            if (!mapTicketProductTicketIds.isEmpty()) {
                Map <Id, CMPL123CME__Concomitant_Product__c> mapConcomitantProductsOld = (Map <Id, CMPL123CME__Concomitant_Product__c>) Trigger.oldMap;
                for (CMPL123CME__Concomitant_Product__c objConcomitantProduct : (List <CMPL123CME__Concomitant_Product__c>) Trigger.new) {
                    if (objConcomitantProduct.CMPL123CME__Related_EMDR__c != null 
                        && objConcomitantProduct.Related_EMDR_Ticket__c != null 
                        && objConcomitantProduct.Product_Ticket__c != null) {
                        if (!mapTicketProductTicketIds
                            .get(objConcomitantProduct.Related_EMDR_Ticket__c)
                            .contains(objConcomitantProduct.Product_Ticket__c)) {
                            objConcomitantProduct.addError(Label.Concomitant_Product_Product_Ticket + ' '
                                                            + JSON.serialize(mapProductTicketIdNames.get(objConcomitantProduct.Related_EMDR_Ticket__c)));
                        } else {
                            // Added - W-000113
                            String strProductName = mapProductTickets.get(objConcomitantProduct.Product_Ticket__c).Product_Name__c + ', '
                                                                          + mapProductTickets.get(objConcomitantProduct.Product_Ticket__c)
                                                                                             .Product_List_Number__c + ', '
                                                                          + mapProductTickets.get(objConcomitantProduct.Product_Ticket__c)
                                                                                             .Batch_Lot_Serial__c;
                            objConcomitantProduct.CMPL123CME__D11_Product__c = strProductName.length() > 50 ? 
                                                                               strProductName.substring(0,50).replace('null','') : 
                                                                               strProductName.replace('null','');
                        }
                    }
                }
            }
        }
    }
}