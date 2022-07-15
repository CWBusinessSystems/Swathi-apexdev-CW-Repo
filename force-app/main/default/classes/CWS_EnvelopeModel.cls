Public class CWS_EnvelopeModel{

    Public class EnvelopeRequest{
        Public Integer accountId {get;set;}
        Public String emailSubject {get;set;}
        Public String emailBlurb {get;set;}
        Public String templateId {get;set;}
        Public List<TemplateRole> templateRoles {get;set;}
        Public List<Document> documents {get;set;}
        Public String status {get;set;}
    }
    
    Public class EnvelopeResponse{
        Public String envelopeId {get;set;}
        Public String uri {get;set;}
        Public String status {get;set;}
        Public String statusDateTime {get;set;}        
    }
    
    Public class TemplateRole{
        Public String roleName {get;set;}
        Public String name {get;set;}
        Public String email {get;set;}
        public String routingOrder {get;set;}
        Public DocusignTabsWrapper tabs {get;set;}
    }
    
    Public class Document{
        Public String documentBase64 {get;set;}
        Public String name {get;set;}
        Public String fileExtension {get;set;}
        Public String documentId {get;set;}
    }
    
    Public class Recipient{
        Public String email {get;set;}
        Public String userName {get;set;}
        public String id {get;set;}
        Public String type_x {get;set;}
        Public String routingOrder {get;set;}
    }
    
    public class DocusignTabsWrapper{
        public List<TabWrapper> textTabs {get;set;}
        public List<TabWrapper> signHereTabs {get;set;}
        public List<TabWrapper> dateSignedTabs {get;set;}
        public List<TabWrapper> initialHereTabs {get;set;}
        public List<TabWrapper> emailAddressTabs {get;set;}
        public List<TabWrapper> fullNameTabs {get;set;}
    }

    public class TabWrapper{
        public String anchorString {get;set;}
        public String value {get;set;}
        public String anchorXOffset {get;set;}
        public String anchorYOffset {get;set;}
        public String anchorUnits {get;set;}
        public String required {get;set;}
        public String locked {get;set;}
        public String font {get;set;}
        public String fontSize {get;set;}
        public String show {get;set;}
        public String configurationType {get;set;}
        public String name {get;set;}
    }
}