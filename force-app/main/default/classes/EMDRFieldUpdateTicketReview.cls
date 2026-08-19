/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : EMDRFieldUpdateTicketReview.
* @Why   : Public clas to perform the auto-population required on EMDR object from Ticket Review.
* @When  : 21-MAR-2017.
* @Where : From EMDRFieldUpdateTicketReview class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                     Modification ID         Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    21-MAR-2017              Work ID / Case ID       Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    27-JUL-2020              Code Audit              Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*   Lakshman               03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G4_Date_received_by_MFG__c to CMPL123CME__G3_Date_received_by_Mfg__c.
* ---------------------------------------------------------------------------------------------------------------------------------------
*   Lakshman               03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G7_Type_of_Report_MultiSelect__c -> CMPL123CME__G6_Type_of_Report__c
* ---------------------------------------------------------------------------------------------------------------------------------------
*   Sameer                 09-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G5_PMA_510_K__c -> CMPL123CME__G4_PMA_510_k__c
* ---------------------------------------------------------------------------------------------------------------------------------------
*   Dinesh Kumar           16-JAN-2024            CHaRM-R4.0           Updated the method "autoPopulateTicketReview"
* ---------------------------------------------------------------------------------------------------------------------------------------
*/

public class EMDRFieldUpdateTicketReview {
    public static Boolean isTRExecuted = false;

    /*
    * @Method       : autoPopulateTicketReview.
    * @Description  : Method to auto Populate fields from Ticket Review if EMDR is created from Ticket Review.
    * @Invoke       : From EMDRTriggerHandler on before insert and before update events.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void autoPopulateTicketReview(){
        if(!isTRExecuted){
            MAP<Id, Ticket_Review__c> ticketReviewMap = new Map<Id, Ticket_Review__c>();
            List<CMPL123CME__EMDR__c> newEMDRs = (List<CMPL123CME__EMDR__c>)Trigger.New;
            Map<Id,CMPL123CME__EMDR__c> oldEMDRMap = (Map<Id,CMPL123CME__EMDR__c>)Trigger.oldMap;
            Map<Id,CMPL123CME__EMDR__c> newEMDRMap = (Map<Id,CMPL123CME__EMDR__c>)Trigger.newMap;

            Set<Id> ticketReviewSet = new Set<Id>();
            for(CMPL123CME__EMDR__c emdr : newEMDRs){
                CMPL123CME__EMDR__c oldEMDR = Trigger.isUpdate && oldEMDRMap != null ? oldEMDRMap.get(emdr.ID) : null;
                if(emdr.Ticket_Review__c != null && (oldEMDR == null
                    || (oldEMDR != null && emdr.Ticket_Review__c != oldEMDR.Ticket_Review__c))){
                    ticketReviewSet.add(emdr.Ticket_Review__c);
                }
            }
            if(ticketReviewSet.size() > 0){
                for(Ticket_Review__c ticketReview  : [SELECT Id,B5_Describe_Event_or_Problem__c, Medical_Assignee_Name__c, Division__c,Country_Submission_Type__c, Field_Action_Number__c,Parent_Awareness_Date__c, H10_Addtl_Mfg_Narrative__c, H9_Correction_Removal_report_No__c,
                                                      Product__c, Product__r.Product_Brand_Name__c, Product__r.Product_Common_Name__c, Product__r.FDA_Product_Code__c,Product__r.Registered_Site__c, Product__r.List_Number__c, Product__r.X510K_Number__c, Product__r.Product_GTIN__c,
                                                      Country_Submission_Type__r.Calendar_Days__c FROM Ticket_Review__c WHERE Id IN : ticketReviewSet]){
                                                          ticketReviewMap.put(ticketReview.Id, ticketReview);
                                                      }
            }
            for(CMPL123CME__EMDR__c emdr : newEMDRs){
                if(emdr.Ticket_Review__c != null && emdr.CMPL123CME__G6_Type_of_Report__c != 'Follow Up'){
                    if(emdr.CMPL123CME__D1_Brand_Name__c == null){
                        emdr.CMPL123CME__D1_Brand_Name__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__c != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.Product_Brand_Name__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.Product_Brand_Name__c : null;
                    }

                    if(emdr.CMPL123CME__D2_Common_Device_Name__c == null){
                        emdr.CMPL123CME__D2_Common_Device_Name__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__c != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.Product_Common_Name__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.Product_Common_Name__c : null;
                    }

                    if(emdr.CMPL123CME__D2b_Procode__c == null){
                        emdr.CMPL123CME__D2b_Procode__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__c != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.FDA_Product_Code__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.FDA_Product_Code__c : null;
                    }

                    if(emdr.CMPL123CME__D4_Catalog_No__c == null){
                        emdr.CMPL123CME__D4_Catalog_No__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__c != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.List_Number__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.List_Number__c : null;
                    }

                    //(SA)if(emdr.CMPL123CME__G5_PMA_510_K__c == null){
                        //emdr.CMPL123CME__G5_PMA_510_K__c = ticketReviewMap != null &&
                    if(emdr.CMPL123CME__G4_PMA_510_k__c == null){
                        emdr.CMPL123CME__G4_PMA_510_k__c = ticketReviewMap != null &&                        
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__c != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.X510K_Number__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.X510K_Number__c : null;
                    }

                    if(emdr.CMPL123CME__Registered_Site__c == null){
                        emdr.CMPL123CME__Registered_Site__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__c != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.Registered_Site__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.Registered_Site__c : null;
                    }
                    //CHaRM-R4: EMDR HL7 Changes replacing "CMPL123CME__Unique_Identifier_UDI__c" discontinued field with new field "CMPL123CME__D4_Primary_UDI_Number__c".
                   /* if(emdr.CMPL123CME__Unique_Identifier_UDI__c == null){
                        emdr.CMPL123CME__Unique_Identifier_UDI__c = ticketReviewMap != null &&*/
                    if(emdr.CMPL123CME__D4_Primary_UDI_Number__c == null){
                        emdr.CMPL123CME__D4_Primary_UDI_Number__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__c != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.Product_GTIN__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Product__r.Product_GTIN__c : null;
                    }
                    if(emdr.CMPL123CME__B5_Describe_Event_or_Problem__c == null){
                        emdr.CMPL123CME__B5_Describe_Event_or_Problem__c =  ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).B5_Describe_Event_or_Problem__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).B5_Describe_Event_or_Problem__c : null;
                    }

                    if(emdr.CMPL123CME__G3_Date_received_by_Mfg__c == null){
                        emdr.CMPL123CME__G3_Date_received_by_Mfg__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Parent_Awareness_Date__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Parent_Awareness_Date__c : null;
                    }

                    //CHaRM-R4: CMPL123CME__H10_Addtl_Mfg_Narrative__c is replaced with CMPL123CME__H11_Additional_Mfg_Narrative__c
                   /* if(emdr.CMPL123CME__H10_Addtl_Mfg_Narrative__c == null){
                    emdr.CMPL123CME__H10_Addtl_Mfg_Narrative__c = ticketReviewMap != null && */
                    if(emdr.CMPL123CME__H11_Additional_Mfg_Narrative__c == null){
                    emdr.CMPL123CME__H11_Additional_Mfg_Narrative__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).H10_Addtl_Mfg_Narrative__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).H10_Addtl_Mfg_Narrative__c : null;
                    }

                    if(emdr.CMPL123CME__H9_Correction_Removal_Report_No__c == null){
                        emdr.CMPL123CME__H9_Correction_Removal_Report_No__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).H9_Correction_Removal_report_No__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).H9_Correction_Removal_report_No__c : null;
                    }

                    if(emdr.Division__c == null){
                        emdr.Division__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Division__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Division__c : null;
                    }

                    if(emdr.Field_Action_Number__c == null){
                        emdr.Field_Action_Number__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Field_Action_Number__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Field_Action_Number__c : null;
                    }

                    if(emdr.Medical_Evaluator__c == null){
                        emdr.Medical_Evaluator__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Medical_Assignee_Name__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Medical_Assignee_Name__c : null;
                    }

                    if(emdr.Products__c == null){
                        emdr.Products__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Product__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Product__c : null;
                    }

                    if(emdr.Submission_Type__c == null){
                        emdr.Submission_Type__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Country_Submission_Type__c != null
                        ? ticketReviewMap.get(emdr.Ticket_Review__c).Country_Submission_Type__c : null;
                    }

                    if(emdr.CMPL123CME__MDR_Due_Date__c == null){
                        emdr.CMPL123CME__MDR_Due_Date__c = ticketReviewMap != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c) != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Parent_Awareness_Date__c != null &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Country_Submission_Type__c != null  &&
                        ticketReviewMap.get(emdr.Ticket_Review__c).Country_Submission_Type__r.Calendar_Days__c != null
                        ? (ticketReviewMap.get(emdr.Ticket_Review__c).Parent_Awareness_Date__c + Integer.valueOf(ticketReviewMap.get(emdr.Ticket_Review__c).Country_Submission_Type__r.Calendar_Days__c)) : null;
                    }
                }
            }
        }
        isTRExecuted=true;
    }

}