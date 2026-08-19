/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3MDITriggerHandler.
* @Why   : Handles all the customization involved on update of MDI object.
* @When  : 23-MAR-2017.
* @Where : From CMPL123CME_MEDDEV_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 23-MAR-2017            Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 11-AUG-2020            Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar          10-Nov-2023            CHaRM-R4/IPDR 576           Updated the method fieldUpdates for the Fix IPDR: 576
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar          20-SEP-2024            CHaRM-R5/IPDR 652           Updated the method fieldUpdates for the Fix IPDR: 652
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDS3MDITriggerHandler{

    // Added for W-000070 -start
    public Static Boolean isExecuted = false;

    /*
    * @Method       : fieldUpdates.
    * @Description  : To handle all the auto populated MDI field values.
    * @Invoke       : From CMPL123CME_MEDDEV_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void fieldUpdates(){
        // Added for W-000070 -(This flag is used to allow a method to execute only once to avoid recursion)-start
        if(!isExecuted){
            //Variable declarations.
            List<CMPL123CME__MEDDEV__c> newMDIs = (List<CMPL123CME__MEDDEV__c>)Trigger.new;
            Set<Id> medicalEvalID = new Set<Id>();
            Set<Id> registeredSite = new Set<Id>();
            Set<Id> countryID = new Set<Id>();
            Set<Id> products = new set<Id>();
            Map<Id,CMPL123CME__Questionnaire__c> commentsMap = new  Map<Id,CMPL123CME__Questionnaire__c>();
            Map<Id,String> productsMap = new Map<Id,String>();
            Map<Id,String> nomenclatureCodes = new Map<Id,String>();
            Map<Id,CMPL123CME__Registered_Site__c> registeredsitesMap = new Map<Id,CMPL123CME__Registered_Site__c>();
            Map<Id, CMPL123CME__MEDDEV__c> oldMDIMap = (Map<Id, CMPL123CME__MEDDEV__c>)Trigger.OldMap;
            Map<Id, Country__c> countryRecordMap = new Map<Id, Country__c>();
            Map<Id, Product_Ticket__c> mapProductTickets = New Map<Id, Product_Ticket__c>();

            //Collect all ralated medical evals, country , product-ticket and registred site record.
            for(CMPL123CME__MEDDEV__c MDIs : newMDIs){
                if(MDIs.Medical_Evaluation__c != null)
                    medicalEvalID.add(MDIs.Medical_Evaluation__c);

                if(Trigger.IsInsert || MDIs.Country__c != oldMDIMap.get(MDIs.Id).Country__c){
                    countryID.add(MDIs.Country__c);
                }

                if(MDIs.Product__c != null)
                    products.add(MDIs.Product__c);

                if(MDIs.Registered_Site__c != null)
                    registeredSite.add(MDIs.Registered_Site__c);
            }
            //Collect MDI12 Comments pf medical evaluation to auto populate in MDI comments
            for(CMPL123CME__Questionnaire__c medEval : [SELECT Id, MDI_12_Comments__c, Division__c, Evaluator__c FROM CMPL123CME__Questionnaire__c
                                                        WHERE Id IN : medicalEvalID]){
                                                            commentsMap.put(medEval.Id,medEval);
                                                        }
            //Collect Country names and primary vigilance contact.

            for(Country__c countries : [SELECT Id, Name, Primary_Vigilance_Contact__c, Primary_Vigilance_Contact__r.Name, Primary_Vigilance_Contact__r.LastName,
                                        Primary_Vigilance_Contact__r.FirstName,Primary_Vigilance_Contact__r.Street, Primary_Vigilance_Contact__r.City, Primary_Vigilance_Contact__r.State,
                                        Primary_Vigilance_Contact__r.PostalCode, Primary_Vigilance_Contact__r.Email, Primary_Vigilance_Contact__r.Phone,
                                        Primary_Vigilance_Contact__r.Fax, Primary_Vigilance_Contact__r.Country FROM Country__c WHERE ID IN: countryID]){
                                            countryRecordMap.put(countries.Id, countries);
                                        }
            //Collect Product-Ticket product Id.
            //CHaRM-R5: Replaced Registered_Site__c with IVDR_Registered_Site__c as the design for MDI is changed and the values be populated from MDI/MIR Registered Site as part of IPDR 652.
            for(Product_Ticket__c productTickets : [SELECT Id, Product__c,
                                                    Product__r.IVDR_Registered_Site__c,
                                                    Product__r.IVDR_Registered_Site__r.Authorised_Rep_Country__c,
                                                    Product__r.IVDR_Registered_Site__r.Manufacturer_Country__c,
                                                    Product__r.Device_Nomenclature_System__c,
                                                    Product__r.Device_Class__c
                                                    FROM Product_Ticket__c WHERE Id IN: products]){
                                                        mapProductTickets.put(productTickets.Id, productTickets);
                                                    }

            //Collect Registration sites.
            for(CMPL123CME__Registered_Site__c regSites: [SELECT Id, CMPL123CME__G1_Contact_Office_Country__c, Authorised_Rep_Country__c, Manufacturer_Country__c
                                                          FROM CMPL123CME__Registered_Site__c WHERE Id IN: registeredSite]){
                                                              registeredsitesMap.put(regSites.Id, regSites);
                                                          }

            for(CMPL123CME__MEDDEV__c MDIs : newMDIs){
                // Processbuilder replacement- Autoset Medical Evaluator in MDI, SOQL optimization
                if(MDIs.Medical_Evaluation__c != null && !medicalEvalID.isEmpty() && commentsMap.containsKey(MDIs.Medical_Evaluation__c)){
                    MDIs.Division__c = commentsMap.get(MDIs.Medical_Evaluation__c).Division__c;
                    // Processbuilder replacement- Autoset Medical Evaluator in MDI, SOQL optimization
                    if(Trigger.IsInsert && MDIs.CMPL123CME__Type_of_Report__c != 'Follow-up report'){
                        MDIs.Regulatory_Evaluator__c = commentsMap.get(MDIs.Medical_Evaluation__c).Evaluator__c;
                    }
                }

                // Update comment value with MDI 12 comment.
                //  CHaRM-R4:Updated the below code and added the Tigger.IsInsert to trigger only on Insert event
                if(Trigger.IsInsert && MDIs.Medical_Evaluation__c != null && MDIs.CMPL123CME__Comments__c == null){
                    String comment  = commentsMap.get(MDIs.Medical_Evaluation__c).MDI_12_Comments__c;
                    MDIs.CMPL123CME__Comments__c = comment != null ? comment : MDIs.CMPL123CME__Comments__c;
                }
                // Updated Class and Nomenclature system (preferable GMDN)
                if(MDIs.Product__c != null && mapProductTickets.containsKey(MDIs.Product__c) && mapProductTickets.get(MDIs.Product__c).Product__c != null){
                    // Processbuilder replacement- Autoset Registered Site in MDI based on Product, SOQL optimization
                    if(MDIs.CMPL123CME__Type_of_Report__c != 'Follow-up report'){
                        //CHaRM-R5: Replaced Registered_Site__c with IVDR_Registered_Site__c as part of IPDR 652
                       MDIs.Registered_Site__c = mapProductTickets.get(MDIs.Product__c).Product__r.IVDR_Registered_Site__c;
                    }

                    // Auto set Country fields in MDI based on Registration Site, SOQL optimization
                    // CHaRM-R4: Updated the below code to add the Null check for Autorised Rep Country field to avoid defaulting the values when updating
                    // CHaRM-R5: Replaced Registered_Site__c with IVDR_Registered_Site__c as part of IPDR 652
                      if(MDIs.CMPL123CME__AuthorisedRepresentativeCountry__c == null && mapProductTickets.get(MDIs.Product__c).Product__r.IVDR_Registered_Site__c != null && MDIs.CMPL123CME__Type_of_Report__c != 'Follow-up report'){
                        MDIs.CMPL123CME__AuthorisedRepresentativeCountry__c = mapProductTickets.get(MDIs.Product__c).Product__r.IVDR_Registered_Site__r.Authorised_Rep_Country__c;
                    }
                    //CHaRM-R4: Added the below Null check for the Nomenclature System Preferable GMDN field to avoid defaulting the values when updating 
                    if(MDIs.CMPL123CME__NomenclatureSystem_preferable_GMDN__c == null){
                    MDIs.CMPL123CME__NomenclatureSystem_preferable_GMDN__c = mapProductTickets.get(MDIs.Product__c).Product__r.Device_Nomenclature_System__c != null ?
                        mapProductTickets.get(MDIs.Product__c).Product__r.Device_Nomenclature_System__c : MDIs.CMPL123CME__NomenclatureSystem_preferable_GMDN__c;
                    }
                    //CHaRM-R4: Added the below Null check for the Class field to avoid defaulting the values when updating 
                    if(MDIs.CMPL123CME__Medical_Device_Class__c == null){
                    MDIs.CMPL123CME__Medical_Device_Class__c = mapProductTickets.get(MDIs.Product__c).Product__r.Device_Class__c != null ?
                        mapProductTickets.get(MDIs.Product__c).Product__r.Device_Class__c : MDIs.CMPL123CME__Medical_Device_Class__c;
                    }
                   // CHaRM-R4: Updated the below code to add the Null check for Autorised Rep Country field to avoid defaulting the values when updating 
                }else if(MDIs.CMPL123CME__AuthorisedRepresentativeCountry__c == null && MDIs.Registered_Site__c != null && registeredsitesMap.containsKey(MDIs.Registered_Site__c) && MDIs.CMPL123CME__Type_of_Report__c != 'Follow-up report'){
                    MDIs.CMPL123CME__AuthorisedRepresentativeCountry__c = registeredsitesMap.get(MDIs.Registered_Site__c).Authorised_Rep_Country__c;
                }

                // Updated Usage of the medical device
                if(MDIs.CMPL123CME__Usage_of_Medical_Device__c == null){
                    MDIs.CMPL123CME__Usage_of_Medical_Device__c = 'Other (please specify)';
                }

                if(MDIs.Country__c != null && countryRecordMap.get(MDIs.Country__c) != null
                   && countryRecordMap.get(MDIs.Country__c).Primary_Vigilance_Contact__c != null){
                       Country__c submissionCountry = countryRecordMap.get(MDIs.Country__c);
                           MDIs.CMPL123CME__Submitter_Contact__c = submissionCountry.Primary_Vigilance_Contact__r.FirstName+' '+submissionCountry.Primary_Vigilance_Contact__r.LastName;
                           MDIs.CMPL123CME__Submitter_Address__c = submissionCountry.Primary_Vigilance_Contact__r.Street;
                           MDIs.CMPL123CME__Submitter_City__c = submissionCountry.Primary_Vigilance_Contact__r.City;
                           MDIs.CMPL123CME__Submitter_Email__c = submissionCountry.Primary_Vigilance_Contact__r.Email;
                           MDIs.CMPL123CME__Submitter_Fax__c = submissionCountry.Primary_Vigilance_Contact__r.Fax;
                           MDIs.CMPL123CME__Submitter_Phone__c = submissionCountry.Primary_Vigilance_Contact__r.Phone;
                           MDIs.CMPL123CME__Submitter_Postal_Code__c = submissionCountry.Primary_Vigilance_Contact__r.PostalCode;
                           MDIs.CMPL123CME__Submitter_Name__c = submissionCountry.Primary_Vigilance_Contact__r.Name;
                           // #1455 critical issue fix
                           MDIs.CMPL123CME__SubmitterCountry__c = submissionCountry.Primary_Vigilance_Contact__r.Country;
                   }

                // Update Expected next report date value
                if(Trigger.isUpdate && MDIs.CMPL123_WF_Action__c != oldMDIMap.get(MDIs.Id).CMPL123_WF_Action__c &&
                   MDIs.CMPL123_WF_Action__c == 'Submit to Regulatory' && MDIs.Division__c == 'ADD' &&
                   //Added - W-000161
                   (MDIs.CMPL123CME__Type_of_Report__c != 'Final report' && MDIs.CMPL123CME__Type_of_Report__c != 'Combined initial and final report')){
                       MDIs.CMPL123CME__Expected_Date_of_Next_Report__c = MDIs.CMPL123_WF_Action_Performed_On__c.Date()+60;
                   }


                //Set Medical device operator during incident as Default to "Health Care Professional"
                MDIs.CMPL123CME__Medical_Device_Operator_During_Incident__c =
                    MDIs.CMPL123CME__Medical_Device_Operator_During_Incident__c == null ? 'Healthcare Professional' :
                MDIs.CMPL123CME__Medical_Device_Operator_During_Incident__c;
            }
        }
        isExecuted=true;
        //Added for W-000070 - End
    }
}