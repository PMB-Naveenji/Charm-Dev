/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ComplaintTicketReportResult.
* @Why   : Utility class.
* @When  : 16-MAY-2019.
* @Where : From ADDComplaintReportController and ComplaintTicketReport classes.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 16-MAY-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 20-AUG-2020            Code Audit                      Updated class comments. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 23-NOV-2020            HC Defect #44                   Updated class structure.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class ComplaintTicketReportResult {

    public List<CMPL123CME__Complaint__c> ticketsList {get; set;}
    public List<pRE_Information__c> pREInformationChilds {get; set;}
    public List<TicketProdEvalWrapper> prodEvalsList {get; set;}
    public List<CMPL123CME__Questionnaire__c> medEvalWithQuestionsList {get; set;}
    public Map<String, List<CMPL123CME__EMDR__c> > emdrStatusMap {get; set;}
    public Map<String, List<CMPL123CME__MEDDEV__c> > medDevStatusMap {get; set;}
    public Map<String, List<CMPL123CME__EU_MIR__c> > euMirStatusMap {get; set;}//@Lakshman
    public Map<String, List<pRE_Question__c> > preQuestionsCategoryMap {get; set;}
    public Map<Id, List<Product_Lot__c>> productsLotsMap {get; set;}
    public Set<Id> attachmentIdSet {get; set;}
    public List<Attachment__c> attachmentList {get; set;}
    //Defect #44 fix BEGIN
    public List <Product_Ticket__c> productTickets {get; set;}
    public List <Contact__c> contacts {get; set;}
    public List <Ticket_Note__c> ticketNotes {get; set;}
    public List <Activity__c> activities {get; set;}
    public List <Customer_Response__c> customerResponses {get; set;}
    public List <Meaningful_Data__c> meaningfulDatas {get; set;}
    //Defect #44 fix END

    public String preQuestionsCategoryMapKeys {get {
        String keys = '';
        for (String key : preQuestionsCategoryMap.keySet()) {
            keys += key + ',';
        }
        return keys.removeEnd(',');
    }}
    public String emdrStatusMapKeys {get {
        String keys = '';
        for (String key : emdrStatusMap.keySet()) {
            keys += key + ',';
        }
        return keys.removeEnd(',');
    }}
    public String medDevStatusMapKeys {get {
        String keys = '';
        for (String key : medDevStatusMap.keySet()) {
            keys += key + ',';
        }
        return keys.removeEnd(',');
    }}
    //@Lakshman
    public String euMirStatusMapKeys {get {
        String keys = '';
        for (String key : euMirStatusMap.keySet()) {
            keys += key + ',';
        }
        return keys.removeEnd(',');
    }}
    public String productsLotsMapKeys {get {
        String keys = '';
        for (String key : productsLotsMap.keySet()) {
            keys += key + ',';
        }
        return keys.removeEnd(',');
    }}
    public Integer emdrStatusMapSize { get { return emdrStatusMap.size(); } }
    public Integer medDevStatusMapSize { get { return medDevStatusMap.size(); } }
    public Integer euMirStatusMapSize { get { return euMirStatusMap.size(); } }//@Lakshman
    public Integer preQuestionsCategoryMapSize { get { return preQuestionsCategoryMap.size(); } }

    /*
    * @Method       : ComplaintTicketReportResult.
    * @Description  : Constructor.
    * @Invoke       : From ADDComplaintReportController and ComplaintTicketReport classes.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public ComplaintTicketReportResult() {
        preQuestionsCategoryMap = new Map<String, List<pRE_Question__c> >();
        emdrStatusMap = new Map<String, List<CMPL123CME__EMDR__c> >();
        medDevStatusMap = new Map<String, List<CMPL123CME__MEDDEV__c> >();
        euMirStatusMap = new Map<String, List<CMPL123CME__EU_MIR__c> >();//@Lakshman
        attachmentIdSet = new Set<Id>();
        attachmentList = new List<Attachment__c>();
        pREInformationChilds = new List<pRE_Information__c>();
        prodEvalsList = new List<TicketProdEvalWrapper>();
        medEvalWithQuestionsList = new List<CMPL123CME__Questionnaire__c>();
        productsLotsMap = new Map<Id, List<Product_Lot__c>> ();
        //Defect #44 fix BEGIN
        productTickets = new List <Product_Ticket__c> ();
        contacts = new List <Contact__c> ();
        ticketNotes = new List <Ticket_Note__c> ();
        activities = new List <Activity__c> ();
        customerResponses = new List <Customer_Response__c> ();
        meaningfulDatas = new List <Meaningful_Data__c> ();
        //Defect #44 fix END
    }
}