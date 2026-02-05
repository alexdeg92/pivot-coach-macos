import Foundation

// MARK: - Pivot Sales Knowledge Base
// Comprehensive knowledge base for Pivot sales coaching
// Bilingual: English & French (Quebec market)

struct PivotKnowledgeBase {
    
    // MARK: - Search Functionality
    
    static func search(query: String, language: Language = .english) -> [SearchResult] {
        let normalizedQuery = query.lowercased()
        var results: [SearchResult] = []
        
        // Search features
        for feature in features {
            let content = language == .french ? feature.descriptionFr : feature.description
            let name = language == .french ? feature.nameFr : feature.name
            if name.lowercased().contains(normalizedQuery) ||
               content.lowercased().contains(normalizedQuery) ||
               feature.keywords.contains(where: { $0.lowercased().contains(normalizedQuery) }) {
                results.append(SearchResult(
                    category: .feature,
                    title: name,
                    content: content,
                    relevance: calculateRelevance(query: normalizedQuery, in: [name, content])
                ))
            }
        }
        
        // Search objections
        for objection in objections {
            let obj = language == .french ? objection.objectionFr : objection.objection
            let reb = language == .french ? objection.rebuttalFr : objection.rebuttal
            if obj.lowercased().contains(normalizedQuery) ||
               reb.lowercased().contains(normalizedQuery) {
                results.append(SearchResult(
                    category: .objection,
                    title: obj,
                    content: reb,
                    relevance: calculateRelevance(query: normalizedQuery, in: [obj, reb])
                ))
            }
        }
        
        // Search competitors
        for competitor in competitors {
            if competitor.name.lowercased().contains(normalizedQuery) ||
               competitor.advantages.joined().lowercased().contains(normalizedQuery) {
                let content = language == .french ? competitor.advantagesFr.joined(separator: "\n• ") : competitor.advantages.joined(separator: "\n• ")
                results.append(SearchResult(
                    category: .competitor,
                    title: competitor.name,
                    content: "• " + content,
                    relevance: calculateRelevance(query: normalizedQuery, in: [competitor.name] + competitor.advantages)
                ))
            }
        }
        
        // Search integrations
        for integration in integrations {
            if integration.name.lowercased().contains(normalizedQuery) ||
               integration.description.lowercased().contains(normalizedQuery) {
                let desc = language == .french ? integration.descriptionFr : integration.description
                results.append(SearchResult(
                    category: .integration,
                    title: integration.name,
                    content: desc,
                    relevance: calculateRelevance(query: normalizedQuery, in: [integration.name, integration.description])
                ))
            }
        }
        
        // Search success stories
        for story in successStories {
            let title = language == .french ? story.titleFr : story.title
            let desc = language == .french ? story.descriptionFr : story.description
            if title.lowercased().contains(normalizedQuery) ||
               desc.lowercased().contains(normalizedQuery) ||
               story.industry.lowercased().contains(normalizedQuery) {
                results.append(SearchResult(
                    category: .successStory,
                    title: title,
                    content: desc,
                    relevance: calculateRelevance(query: normalizedQuery, in: [title, desc])
                ))
            }
        }
        
        return results.sorted { $0.relevance > $1.relevance }
    }
    
    private static func calculateRelevance(query: String, in texts: [String]) -> Double {
        var score = 0.0
        for text in texts {
            if text.lowercased() == query { score += 1.0 }
            else if text.lowercased().hasPrefix(query) { score += 0.8 }
            else if text.lowercased().contains(query) { score += 0.5 }
        }
        return min(score, 1.0)
    }
    
    // MARK: - Types
    
    enum Language: String, CaseIterable, Sendable {
        case english = "en"
        case french = "fr"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .french: return "Français"
            }
        }
    }
    
    enum SearchCategory: String, CaseIterable, Sendable {
        case feature = "Feature"
        case objection = "Objection"
        case competitor = "Competitor"
        case integration = "Integration"
        case successStory = "Success Story"
        case pricing = "Pricing"
        
        var icon: String {
            switch self {
            case .feature: return "star.fill"
            case .objection: return "exclamationmark.bubble.fill"
            case .competitor: return "person.2.fill"
            case .integration: return "link"
            case .successStory: return "trophy.fill"
            case .pricing: return "dollarsign.circle.fill"
            }
        }
    }
    
    struct SearchResult: Identifiable, Sendable {
        let id = UUID()
        let category: SearchCategory
        let title: String
        let content: String
        let relevance: Double
    }
    
    struct Feature: Identifiable, Sendable {
        let id = UUID()
        let name: String
        let nameFr: String
        let description: String
        let descriptionFr: String
        let benefits: [String]
        let benefitsFr: [String]
        let keywords: [String]
        let icon: String
    }
    
    struct PricingTier: Identifiable, Sendable {
        let id = UUID()
        let name: String
        let nameFr: String
        let pricePerEmployee: Double
        let minimumEmployees: Int
        let features: [String]
        let featuresFr: [String]
        let valueProposition: String
        let valuePropositionFr: String
        let idealFor: String
        let idealForFr: String
    }
    
    struct Competitor: Identifiable, Sendable {
        let id = UUID()
        let name: String
        let advantages: [String]
        let advantagesFr: [String]
        let weaknesses: [String]
        let weaknessesFr: [String]
        let typicalPricing: String
        let marketPosition: String
    }
    
    struct Objection: Identifiable, Sendable {
        let id: UUID
        let category: String
        let objection: String
        let objectionFr: String
        let rebuttal: String
        let rebuttalFr: String
        let followUpQuestions: [String]
        let followUpQuestionsFr: [String]
        
        init(category: String, objection: String, objectionFr: String, rebuttal: String, rebuttalFr: String, followUpQuestions: [String], followUpQuestionsFr: [String]) {
            self.id = UUID()
            self.category = category
            self.objection = objection
            self.objectionFr = objectionFr
            self.rebuttal = rebuttal
            self.rebuttalFr = rebuttalFr
            self.followUpQuestions = followUpQuestions
            self.followUpQuestionsFr = followUpQuestionsFr
        }
    }
    
    struct SuccessStory: Identifiable, Sendable {
        let id = UUID()
        let title: String
        let titleFr: String
        let industry: String
        let companySize: String
        let description: String
        let descriptionFr: String
        let metrics: [String: String]
        let quote: String
        let quoteFr: String
    }
    
    struct Integration: Identifiable, Sendable {
        let id = UUID()
        let name: String
        let category: String
        let description: String
        let descriptionFr: String
        let setupTime: String
        let features: [String]
    }
    
    // MARK: - Features
    
    static let features: [Feature] = [
        Feature(
            name: "Smart Scheduling",
            nameFr: "Planification Intelligente",
            description: "AI-powered scheduling that considers employee availability, skills, labor laws, and business needs. Create optimal schedules in minutes, not hours.",
            descriptionFr: "Planification propulsée par l'IA qui considère la disponibilité des employés, leurs compétences, les lois du travail et les besoins de l'entreprise. Créez des horaires optimaux en minutes, pas en heures.",
            benefits: [
                "Reduce scheduling time by 80%",
                "Automatic compliance with Quebec labor laws",
                "Smart shift swapping with manager approval",
                "Demand-based scheduling using historical data",
                "Conflict detection and resolution"
            ],
            benefitsFr: [
                "Réduisez le temps de planification de 80%",
                "Conformité automatique aux lois du travail du Québec",
                "Échange de quarts intelligent avec approbation du gestionnaire",
                "Planification basée sur la demande historique",
                "Détection et résolution des conflits"
            ],
            keywords: ["schedule", "horaire", "shift", "quart", "availability", "disponibilité", "planning"],
            icon: "calendar"
        ),
        Feature(
            name: "Time & Attendance",
            nameFr: "Temps et Présence",
            description: "Accurate time tracking with GPS verification, biometric options, and automatic break compliance. Eliminate buddy punching and time theft.",
            descriptionFr: "Suivi du temps précis avec vérification GPS, options biométriques et conformité automatique des pauses. Éliminez le pointage par procuration et le vol de temps.",
            benefits: [
                "GPS geofencing ensures on-site clock-in",
                "Photo verification option",
                "Automatic break reminders and compliance",
                "Real-time labor cost tracking",
                "Overtime alerts and management"
            ],
            benefitsFr: [
                "Géorepérage GPS assure le pointage sur site",
                "Option de vérification par photo",
                "Rappels automatiques de pause et conformité",
                "Suivi des coûts de main-d'œuvre en temps réel",
                "Alertes et gestion des heures supplémentaires"
            ],
            keywords: ["time", "temps", "clock", "punch", "pointage", "attendance", "présence", "GPS"],
            icon: "clock.fill"
        ),
        Feature(
            name: "Integrated Payroll",
            nameFr: "Paie Intégrée",
            description: "Seamless payroll processing with automatic time data integration. Support for Quebec-specific deductions, vacation pay, and statutory holidays.",
            descriptionFr: "Traitement de paie fluide avec intégration automatique des données de temps. Support pour les déductions spécifiques au Québec, les vacances et les jours fériés.",
            benefits: [
                "One-click payroll from timesheet data",
                "Automatic Quebec tax calculations (Revenu Québec compliant)",
                "Direct deposit and pay stub generation",
                "Year-end T4/Relevé 1 preparation",
                "Tip income reporting and distribution"
            ],
            benefitsFr: [
                "Paie en un clic à partir des feuilles de temps",
                "Calculs automatiques des taxes québécoises (conforme à Revenu Québec)",
                "Dépôt direct et génération des talons de paie",
                "Préparation des T4/Relevé 1 de fin d'année",
                "Déclaration et distribution des pourboires"
            ],
            keywords: ["payroll", "paie", "salary", "salaire", "tax", "impôt", "deduction", "déduction"],
            icon: "dollarsign.circle.fill"
        ),
        Feature(
            name: "POS Integration",
            nameFr: "Intégration Point de Vente",
            description: "Deep integration with major POS systems for real-time sales data, labor cost optimization, and demand forecasting.",
            descriptionFr: "Intégration profonde avec les principaux systèmes de point de vente pour les données de ventes en temps réel, l'optimisation des coûts de main-d'œuvre et les prévisions de la demande.",
            benefits: [
                "Real-time sales vs labor dashboard",
                "Automatic schedule optimization based on sales",
                "Historical sales data for demand forecasting",
                "Labor cost percentage tracking",
                "Peak hour identification"
            ],
            benefitsFr: [
                "Tableau de bord ventes vs main-d'œuvre en temps réel",
                "Optimisation automatique des horaires selon les ventes",
                "Données de ventes historiques pour prévision de la demande",
                "Suivi du pourcentage des coûts de main-d'œuvre",
                "Identification des heures de pointe"
            ],
            keywords: ["POS", "point of sale", "point de vente", "sales", "ventes", "Clover", "Square", "Lightspeed"],
            icon: "creditcard.fill"
        ),
        Feature(
            name: "Tips Management",
            nameFr: "Gestion des Pourboires",
            description: "Comprehensive tip pooling, distribution, and reporting. Full compliance with Quebec tip reporting requirements.",
            descriptionFr: "Mise en commun, distribution et rapports complets des pourboires. Pleine conformité avec les exigences de déclaration des pourboires du Québec.",
            benefits: [
                "Flexible tip pooling configurations",
                "Automatic tip distribution calculations",
                "Support for tip-out to kitchen/support staff",
                "Digital tip declaration for employees",
                "Revenu Québec compliant tip reporting"
            ],
            benefitsFr: [
                "Configurations flexibles de mise en commun des pourboires",
                "Calculs automatiques de distribution des pourboires",
                "Support pour le partage avec cuisine/personnel de soutien",
                "Déclaration numérique des pourboires pour les employés",
                "Rapports de pourboires conformes à Revenu Québec"
            ],
            keywords: ["tips", "pourboires", "gratuity", "pooling", "distribution", "tip-out"],
            icon: "banknote.fill"
        ),
        Feature(
            name: "Employee Management",
            nameFr: "Gestion des Employés",
            description: "Complete employee lifecycle management from onboarding to offboarding. Digital HR files, certifications tracking, and performance management.",
            descriptionFr: "Gestion complète du cycle de vie des employés de l'intégration au départ. Dossiers RH numériques, suivi des certifications et gestion de la performance.",
            benefits: [
                "Digital onboarding with e-signatures",
                "Certification and training tracking",
                "Document storage (contracts, IDs, permits)",
                "Performance reviews and feedback",
                "Communication and messaging"
            ],
            benefitsFr: [
                "Intégration numérique avec signatures électroniques",
                "Suivi des certifications et formations",
                "Stockage de documents (contrats, pièces d'identité, permis)",
                "Évaluations de performance et rétroaction",
                "Communication et messagerie"
            ],
            keywords: ["employee", "employé", "HR", "RH", "onboarding", "intégration", "performance"],
            icon: "person.3.fill"
        ),
        Feature(
            name: "Advanced Reporting",
            nameFr: "Rapports Avancés",
            description: "Actionable insights with customizable dashboards and reports. Track labor costs, productivity, and key performance indicators.",
            descriptionFr: "Informations exploitables avec tableaux de bord et rapports personnalisables. Suivez les coûts de main-d'œuvre, la productivité et les indicateurs de performance clés.",
            benefits: [
                "Real-time labor cost tracking",
                "Customizable KPI dashboards",
                "Scheduled report delivery",
                "Export to Excel/CSV",
                "Multi-location comparison"
            ],
            benefitsFr: [
                "Suivi des coûts de main-d'œuvre en temps réel",
                "Tableaux de bord KPI personnalisables",
                "Livraison programmée des rapports",
                "Export vers Excel/CSV",
                "Comparaison multi-établissements"
            ],
            keywords: ["report", "rapport", "analytics", "analytique", "dashboard", "tableau de bord", "KPI"],
            icon: "chart.bar.fill"
        ),
        Feature(
            name: "Mobile App",
            nameFr: "Application Mobile",
            description: "Full-featured mobile app for managers and employees. Schedule viewing, time clock, shift swapping, and team communication on the go.",
            descriptionFr: "Application mobile complète pour gestionnaires et employés. Consultation des horaires, pointage, échange de quarts et communication d'équipe en déplacement.",
            benefits: [
                "View schedules anytime, anywhere",
                "Mobile clock-in with GPS",
                "Request time off and shift swaps",
                "Receive notifications and updates",
                "Team messaging and announcements"
            ],
            benefitsFr: [
                "Consultez les horaires n'importe quand, n'importe où",
                "Pointage mobile avec GPS",
                "Demandez des congés et échanges de quarts",
                "Recevez des notifications et mises à jour",
                "Messagerie d'équipe et annonces"
            ],
            keywords: ["mobile", "app", "application", "iOS", "Android", "phone", "téléphone"],
            icon: "iphone"
        ),
        Feature(
            name: "Labor Compliance",
            nameFr: "Conformité du Travail",
            description: "Automatic compliance with Quebec labor standards (Loi sur les normes du travail). Overtime rules, break requirements, and scheduling regulations.",
            descriptionFr: "Conformité automatique avec les normes du travail du Québec (Loi sur les normes du travail). Règles d'heures supplémentaires, exigences de pause et réglementations d'horaire.",
            benefits: [
                "Quebec labor law compliance built-in",
                "Automatic overtime calculations",
                "Mandatory break enforcement",
                "Minor employee hour restrictions",
                "Scheduling notice requirements (Bill 176)"
            ],
            benefitsFr: [
                "Conformité aux lois du travail du Québec intégrée",
                "Calculs automatiques des heures supplémentaires",
                "Application des pauses obligatoires",
                "Restrictions d'heures pour employés mineurs",
                "Exigences de préavis d'horaire (Loi 176)"
            ],
            keywords: ["compliance", "conformité", "labor law", "loi du travail", "normes", "overtime", "heures supplémentaires"],
            icon: "checkmark.shield.fill"
        ),
        Feature(
            name: "Team Communication",
            nameFr: "Communication d'Équipe",
            description: "Built-in messaging for teams with announcements, group chats, and direct messages. Keep everyone informed and connected.",
            descriptionFr: "Messagerie intégrée pour les équipes avec annonces, discussions de groupe et messages directs. Gardez tout le monde informé et connecté.",
            benefits: [
                "Broadcast announcements to all staff",
                "Department and location groups",
                "Read receipts and delivery confirmation",
                "File and photo sharing",
                "Urgent notification priority"
            ],
            benefitsFr: [
                "Diffusez des annonces à tout le personnel",
                "Groupes par département et établissement",
                "Confirmations de lecture et de livraison",
                "Partage de fichiers et photos",
                "Priorité des notifications urgentes"
            ],
            keywords: ["communication", "message", "chat", "announcement", "annonce", "team", "équipe"],
            icon: "bubble.left.and.bubble.right.fill"
        )
    ]
    
    // MARK: - Pricing Tiers
    
    static let pricingTiers: [PricingTier] = [
        PricingTier(
            name: "Starter",
            nameFr: "Démarrage",
            pricePerEmployee: 2.50,
            minimumEmployees: 5,
            features: [
                "Scheduling",
                "Time & Attendance",
                "Mobile App",
                "Basic Reporting",
                "Email Support"
            ],
            featuresFr: [
                "Planification",
                "Temps et Présence",
                "Application Mobile",
                "Rapports de base",
                "Support par courriel"
            ],
            valueProposition: "Perfect for small businesses getting started with workforce management. All the essentials at an affordable price.",
            valuePropositionFr: "Parfait pour les petites entreprises qui débutent avec la gestion de la main-d'œuvre. Tous les essentiels à un prix abordable.",
            idealFor: "Small restaurants, cafés, retail shops (5-15 employees)",
            idealForFr: "Petits restaurants, cafés, boutiques (5-15 employés)"
        ),
        PricingTier(
            name: "Professional",
            nameFr: "Professionnel",
            pricePerEmployee: 4.00,
            minimumEmployees: 10,
            features: [
                "Everything in Starter",
                "POS Integrations",
                "Tips Management",
                "Advanced Reporting",
                "Labor Compliance Tools",
                "Priority Support"
            ],
            featuresFr: [
                "Tout dans Démarrage",
                "Intégrations Point de Vente",
                "Gestion des Pourboires",
                "Rapports Avancés",
                "Outils de Conformité du Travail",
                "Support Prioritaire"
            ],
            valueProposition: "Full-featured solution for growing businesses. Deep POS integration and compliance tools maximize efficiency and minimize risk.",
            valuePropositionFr: "Solution complète pour les entreprises en croissance. Intégration POS approfondie et outils de conformité maximisent l'efficacité et minimisent les risques.",
            idealFor: "Growing restaurants, bars, multi-location retail (15-50 employees)",
            idealForFr: "Restaurants en croissance, bars, commerce de détail multi-établissements (15-50 employés)"
        ),
        PricingTier(
            name: "Enterprise",
            nameFr: "Entreprise",
            pricePerEmployee: 3.50,
            minimumEmployees: 50,
            features: [
                "Everything in Professional",
                "Integrated Payroll",
                "Multi-location Management",
                "Custom Integrations",
                "Dedicated Account Manager",
                "24/7 Phone Support",
                "Custom Training",
                "SLA Guarantee"
            ],
            featuresFr: [
                "Tout dans Professionnel",
                "Paie Intégrée",
                "Gestion Multi-établissements",
                "Intégrations Personnalisées",
                "Gestionnaire de Compte Dédié",
                "Support Téléphonique 24/7",
                "Formation Personnalisée",
                "Garantie SLA"
            ],
            valueProposition: "Complete workforce management platform with payroll. Lower per-employee cost at scale with premium support and customization.",
            valuePropositionFr: "Plateforme complète de gestion de main-d'œuvre avec paie. Coût par employé réduit à grande échelle avec support premium et personnalisation.",
            idealFor: "Restaurant groups, hotel chains, large retail operations (50+ employees)",
            idealForFr: "Groupes de restaurants, chaînes hôtelières, grandes opérations de détail (50+ employés)"
        )
    ]
    
    // MARK: - Competitors
    
    static let competitors: [Competitor] = [
        Competitor(
            name: "7shifts",
            advantages: [
                "Quebec-first: Built for Quebec labor laws and bilingual from day one",
                "True POS integration: Real-time sales data, not just basic connection",
                "Tips management: Complete tip pooling and Revenu Québec compliance",
                "Better value: More features at lower price points",
                "Local support: Quebec-based support team, not US call center"
            ],
            advantagesFr: [
                "Québec d'abord: Conçu pour les lois du travail québécoises et bilingue dès le départ",
                "Vraie intégration POS: Données de ventes en temps réel, pas juste une connexion de base",
                "Gestion des pourboires: Mise en commun complète et conformité Revenu Québec",
                "Meilleur rapport qualité-prix: Plus de fonctionnalités à des prix inférieurs",
                "Support local: Équipe de support basée au Québec, pas un centre d'appels américain"
            ],
            weaknesses: [
                "Strong brand recognition in restaurant industry",
                "Large existing user base",
                "Good mobile app"
            ],
            weaknessesFr: [
                "Forte reconnaissance de marque dans l'industrie de la restauration",
                "Grande base d'utilisateurs existante",
                "Bonne application mobile"
            ],
            typicalPricing: "$29.99-$99.99/location/month + per user fees",
            marketPosition: "Restaurant-focused scheduling, US-centric"
        ),
        Competitor(
            name: "Deputy",
            advantages: [
                "Quebec compliance: Automatic Bill 176 scheduling notice compliance",
                "Better payroll: Full Quebec payroll, not just time export",
                "Localization: True French interface, not just translated",
                "Cost transparency: Simple per-employee pricing vs complex tiers",
                "Tips handling: Built-in Quebec-compliant tip management"
            ],
            advantagesFr: [
                "Conformité québécoise: Conformité automatique au préavis d'horaire Loi 176",
                "Meilleure paie: Paie québécoise complète, pas juste export de temps",
                "Localisation: Vraie interface française, pas juste traduite",
                "Transparence des coûts: Prix simple par employé vs niveaux complexes",
                "Gestion des pourboires: Gestion des pourboires conforme au Québec intégrée"
            ],
            weaknesses: [
                "Enterprise-grade platform",
                "Strong international presence",
                "Good API and integrations"
            ],
            weaknessesFr: [
                "Plateforme de niveau entreprise",
                "Forte présence internationale",
                "Bonne API et intégrations"
            ],
            typicalPricing: "$4.50-$6/user/month",
            marketPosition: "Enterprise shift scheduling, Australian origin"
        ),
        Competitor(
            name: "Homebase",
            advantages: [
                "No free tier limitations: Full features without employee caps",
                "Quebec-specific: Quebec labor compliance vs generic US-focused",
                "Tips included: Full tip management, not an add-on",
                "Better POS depth: Real-time integration vs basic sync",
                "Payroll option: Full Canadian payroll, not just US"
            ],
            advantagesFr: [
                "Pas de limites sur le niveau gratuit: Fonctionnalités complètes sans plafond d'employés",
                "Spécifique au Québec: Conformité aux lois du travail du Québec vs générique US",
                "Pourboires inclus: Gestion complète des pourboires, pas un ajout",
                "Meilleure profondeur POS: Intégration en temps réel vs synchronisation de base",
                "Option de paie: Paie canadienne complète, pas juste US"
            ],
            weaknesses: [
                "Free tier attracts small businesses",
                "Simple and easy to use",
                "Good for very small teams"
            ],
            weaknessesFr: [
                "Le niveau gratuit attire les petites entreprises",
                "Simple et facile à utiliser",
                "Bon pour les très petites équipes"
            ],
            typicalPricing: "Free-$99.95/location/month",
            marketPosition: "SMB-focused, freemium model, US-centric"
        ),
        Competitor(
            name: "When I Work",
            advantages: [
                "Quebec compliance built-in: Not a US product adapted",
                "Tips management: Complete solution vs none",
                "POS integration: Real-time sales data integration",
                "Payroll: Quebec payroll included, not separate",
                "Support: Local Quebec support vs US timezone"
            ],
            advantagesFr: [
                "Conformité québécoise intégrée: Pas un produit américain adapté",
                "Gestion des pourboires: Solution complète vs aucune",
                "Intégration POS: Intégration des données de ventes en temps réel",
                "Paie: Paie québécoise incluse, pas séparée",
                "Support: Support local au Québec vs fuseau horaire US"
            ],
            weaknesses: [
                "Simple and affordable",
                "Good mobile experience",
                "Wide industry applicability"
            ],
            weaknessesFr: [
                "Simple et abordable",
                "Bonne expérience mobile",
                "Large applicabilité industrielle"
            ],
            typicalPricing: "$2-$8/user/month",
            marketPosition: "General scheduling, broad market appeal"
        ),
        Competitor(
            name: "Toast",
            advantages: [
                "Hardware freedom: Works with any POS, not locked to Toast",
                "Quebec-native: Built for Quebec, not adapted from US",
                "Full workforce: Complete HR and payroll, not just scheduling",
                "Lower total cost: No hardware requirements or contracts",
                "Integration flexibility: Works with Clover, Lightspeed, Square"
            ],
            advantagesFr: [
                "Liberté matérielle: Fonctionne avec n'importe quel POS, pas verrouillé à Toast",
                "Natif du Québec: Conçu pour le Québec, pas adapté des US",
                "Main-d'œuvre complète: RH et paie complètes, pas juste planification",
                "Coût total inférieur: Pas d'exigences matérielles ni de contrats",
                "Flexibilité d'intégration: Fonctionne avec Clover, Lightspeed, Square"
            ],
            weaknesses: [
                "Full ecosystem (POS + workforce)",
                "Restaurant-specific features",
                "Strong brand in restaurant tech"
            ],
            weaknessesFr: [
                "Écosystème complet (POS + main-d'œuvre)",
                "Fonctionnalités spécifiques aux restaurants",
                "Forte marque dans la tech restauration"
            ],
            typicalPricing: "Part of Toast ecosystem, $50-150+/month",
            marketPosition: "Restaurant POS ecosystem, US-dominant"
        )
    ]
    
    // MARK: - Objections and Rebuttals
    
    static let objections: [Objection] = [
        // Price Objections
        Objection(
            category: "Price",
            objection: "It's too expensive / We can't afford it",
            objectionFr: "C'est trop cher / On n'a pas les moyens",
            rebuttal: "I understand budget is important. Let's look at the real cost: How many hours per week does your manager spend on scheduling? At $25/hour, even 4 hours weekly is $400/month. Pivot typically reduces this by 80%, plus eliminates costly overtime errors and compliance violations. Most clients see positive ROI within 60 days.",
            rebuttalFr: "Je comprends que le budget est important. Regardons le vrai coût: Combien d'heures par semaine votre gestionnaire passe-t-il sur la planification? À 25$/heure, même 4 heures par semaine c'est 400$/mois. Pivot réduit typiquement cela de 80%, plus élimine les erreurs coûteuses d'heures supplémentaires et les violations de conformité. La plupart des clients voient un ROI positif en 60 jours.",
            followUpQuestions: [
                "How many hours weekly do you spend on scheduling?",
                "What's the cost when an overtime error happens?",
                "Have you had any compliance issues in the past year?"
            ],
            followUpQuestionsFr: [
                "Combien d'heures par semaine passez-vous sur la planification?",
                "Quel est le coût quand une erreur d'heures supplémentaires arrive?",
                "Avez-vous eu des problèmes de conformité dans la dernière année?"
            ]
        ),
        Objection(
            category: "Price",
            objection: "Your competitor is cheaper",
            objectionFr: "Votre concurrent est moins cher",
            rebuttal: "Let's compare apples to apples. What's included in that price? Many competitors charge extra for tips management, POS integration, and Quebec compliance features. With Pivot, everything is included. Plus, we're the only solution built specifically for Quebec - others are US products adapted for Canada. What specific features are you comparing?",
            rebuttalFr: "Comparons des pommes avec des pommes. Qu'est-ce qui est inclus dans ce prix? Plusieurs concurrents chargent extra pour la gestion des pourboires, l'intégration POS et les fonctionnalités de conformité québécoise. Avec Pivot, tout est inclus. De plus, nous sommes la seule solution conçue spécifiquement pour le Québec - les autres sont des produits américains adaptés pour le Canada. Quelles fonctionnalités spécifiques comparez-vous?",
            followUpQuestions: [
                "Does their price include tips management?",
                "Is Quebec labor compliance built-in or an add-on?",
                "What about payroll - is that extra?"
            ],
            followUpQuestionsFr: [
                "Est-ce que leur prix inclut la gestion des pourboires?",
                "La conformité aux lois du travail du Québec est-elle intégrée ou un ajout?",
                "Et la paie - c'est extra?"
            ]
        ),
        
        // Switching Cost Objections
        Objection(
            category: "Switching",
            objection: "Switching would be too disruptive / We're too busy",
            objectionFr: "Le changement serait trop perturbant / On est trop occupés",
            rebuttal: "That's exactly why we built a white-glove onboarding process. We handle the data migration, we train your team (on YOUR schedule), and we run parallel with your current system until you're confident. Most clients are fully operational in under 2 weeks with zero disruption. When would be the least busy time for a 30-minute demo?",
            rebuttalFr: "C'est exactement pourquoi nous avons créé un processus d'intégration clé en main. Nous gérons la migration des données, nous formons votre équipe (selon VOTRE horaire), et nous fonctionnons en parallèle avec votre système actuel jusqu'à ce que vous soyez confiant. La plupart des clients sont pleinement opérationnels en moins de 2 semaines sans perturbation. Quel serait le moment le moins occupé pour une démo de 30 minutes?",
            followUpQuestions: [
                "What's your slowest period?",
                "Who would need to be trained?",
                "What's your current biggest scheduling pain point?"
            ],
            followUpQuestionsFr: [
                "Quelle est votre période la plus tranquille?",
                "Qui aurait besoin d'être formé?",
                "Quel est votre plus grand problème de planification actuel?"
            ]
        ),
        Objection(
            category: "Switching",
            objection: "We just signed a contract with another provider",
            objectionFr: "On vient de signer un contrat avec un autre fournisseur",
            rebuttal: "I appreciate your honesty. How long is that contract, and are you happy with the solution so far? Many of our clients came from competitors - we can often help with the transition when your contract ends. In the meantime, let me show you what Pivot can do so you can make an informed comparison. Would a demo now help you know what to look for when your contract is up?",
            rebuttalFr: "J'apprécie votre honnêteté. Quelle est la durée de ce contrat, et êtes-vous satisfait de la solution jusqu'à présent? Plusieurs de nos clients venaient de concurrents - nous pouvons souvent aider avec la transition quand votre contrat se termine. En attendant, laissez-moi vous montrer ce que Pivot peut faire pour que vous puissiez faire une comparaison informée. Une démo maintenant vous aiderait-elle à savoir quoi chercher quand votre contrat se terminera?",
            followUpQuestions: [
                "When does your current contract end?",
                "What's working well with your current solution?",
                "What would you change if you could?"
            ],
            followUpQuestionsFr: [
                "Quand votre contrat actuel se termine-t-il?",
                "Qu'est-ce qui fonctionne bien avec votre solution actuelle?",
                "Qu'est-ce que vous changeriez si vous pouviez?"
            ]
        ),
        
        // Training Objections
        Objection(
            category: "Training",
            objection: "My staff won't learn a new system / They're not tech-savvy",
            objectionFr: "Mon personnel n'apprendra pas un nouveau système / Ils ne sont pas à l'aise avec la technologie",
            rebuttal: "That's one of the most common concerns, and it's why we designed Pivot to be incredibly simple. The employee mobile app is easier than ordering from DoorDash - view schedule, clock in, request time off. That's it. We've had 60-year-old dishwashers using it within 10 minutes. For managers, we provide unlimited training sessions. Can I show you how simple the employee experience is?",
            rebuttalFr: "C'est l'une des préoccupations les plus courantes, et c'est pourquoi nous avons conçu Pivot pour être incroyablement simple. L'application mobile pour employés est plus facile que de commander sur DoorDash - voir l'horaire, pointer, demander un congé. C'est tout. Nous avons eu des plongeurs de 60 ans qui l'utilisaient en 10 minutes. Pour les gestionnaires, nous offrons des sessions de formation illimitées. Puis-je vous montrer à quel point l'expérience employé est simple?",
            followUpQuestions: [
                "Do your employees have smartphones?",
                "How do they currently find out their schedule?",
                "What would make adoption easier for them?"
            ],
            followUpQuestionsFr: [
                "Est-ce que vos employés ont des téléphones intelligents?",
                "Comment découvrent-ils actuellement leur horaire?",
                "Qu'est-ce qui faciliterait l'adoption pour eux?"
            ]
        ),
        Objection(
            category: "Training",
            objection: "We don't have time for training",
            objectionFr: "On n'a pas le temps pour la formation",
            rebuttal: "I hear you - time is your most valuable resource. That's why our training is flexible: live sessions, on-demand videos, or we can train during your slow hours. Most managers are comfortable with Pivot after just 2 hours of training, and employees typically need less than 15 minutes. The time you invest now saves you 4-6 hours every week. When are your quietest 2 hours?",
            rebuttalFr: "Je vous entends - le temps est votre ressource la plus précieuse. C'est pourquoi notre formation est flexible: sessions en direct, vidéos à la demande, ou nous pouvons former pendant vos heures tranquilles. La plupart des gestionnaires sont à l'aise avec Pivot après seulement 2 heures de formation, et les employés ont typiquement besoin de moins de 15 minutes. Le temps que vous investissez maintenant vous économise 4-6 heures chaque semaine. Quelles sont vos 2 heures les plus tranquilles?",
            followUpQuestions: [
                "What hours are slowest for you?",
                "Would on-demand video training work better?",
                "How many managers would need training?"
            ],
            followUpQuestionsFr: [
                "Quelles heures sont les plus tranquilles pour vous?",
                "Est-ce que la formation vidéo à la demande fonctionnerait mieux?",
                "Combien de gestionnaires auraient besoin de formation?"
            ]
        ),
        
        // Existing Solution Objections
        Objection(
            category: "Existing Solution",
            objection: "We use Excel/paper and it works fine",
            objectionFr: "On utilise Excel/papier et ça fonctionne bien",
            rebuttal: "I respect that you've made it work! But let me ask - how much time does it take? What happens when someone calls in sick at 6 AM? How do you track overtime compliance? Excel can't alert you to scheduling conflicts, can't let employees swap shifts, can't integrate with your POS. What if I could show you how to cut your scheduling time in half while eliminating those 6 AM scrambles?",
            rebuttalFr: "Je respecte que vous avez fait en sorte que ça fonctionne! Mais laissez-moi demander - combien de temps ça prend? Qu'est-ce qui se passe quand quelqu'un appelle malade à 6h du matin? Comment suivez-vous la conformité des heures supplémentaires? Excel ne peut pas vous alerter des conflits d'horaire, ne peut pas laisser les employés échanger des quarts, ne peut pas s'intégrer à votre POS. Et si je pouvais vous montrer comment couper votre temps de planification en deux tout en éliminant ces paniques de 6h du matin?",
            followUpQuestions: [
                "How many hours do you spend on scheduling weekly?",
                "What happens when there's a last-minute callout?",
                "How do you handle shift swap requests?"
            ],
            followUpQuestionsFr: [
                "Combien d'heures passez-vous sur la planification par semaine?",
                "Que se passe-t-il lors d'un appel de dernière minute?",
                "Comment gérez-vous les demandes d'échange de quarts?"
            ]
        ),
        Objection(
            category: "Existing Solution",
            objection: "Our POS has scheduling built-in",
            objectionFr: "Notre POS a la planification intégrée",
            rebuttal: "Many POS systems offer basic scheduling, but it's not their core focus. How does it handle Quebec labor compliance? Tips management? What about shift swapping or employee communication? Pivot is purpose-built for workforce management and integrates WITH your POS to give you the best of both worlds - real-time sales data powering smart scheduling. What's the biggest limitation of your current POS scheduling?",
            rebuttalFr: "Plusieurs systèmes POS offrent une planification de base, mais ce n'est pas leur focus principal. Comment gère-t-il la conformité aux lois du travail du Québec? La gestion des pourboires? Et les échanges de quarts ou la communication avec les employés? Pivot est conçu spécifiquement pour la gestion de main-d'œuvre et s'intègre AVEC votre POS pour vous donner le meilleur des deux mondes - données de ventes en temps réel alimentant une planification intelligente. Quelle est la plus grande limitation de la planification de votre POS actuel?",
            followUpQuestions: [
                "Does your POS scheduling handle tip distribution?",
                "Can employees swap shifts through it?",
                "Does it track Quebec overtime rules automatically?"
            ],
            followUpQuestionsFr: [
                "Est-ce que la planification de votre POS gère la distribution des pourboires?",
                "Les employés peuvent-ils échanger des quarts à travers?",
                "Est-ce qu'il suit automatiquement les règles d'heures supplémentaires du Québec?"
            ]
        ),
        
        // Trust/Risk Objections
        Objection(
            category: "Trust",
            objection: "I've never heard of Pivot",
            objectionFr: "Je n'ai jamais entendu parler de Pivot",
            rebuttal: "That's fair - we're focused on the Quebec market rather than global brand building. We're used by over [X] restaurants and businesses across Quebec. Would testimonials from similar businesses help? I can also connect you with a reference customer in your industry. What would help you feel confident about Pivot?",
            rebuttalFr: "C'est juste - nous sommes concentrés sur le marché québécois plutôt que sur la construction d'une marque mondiale. Nous sommes utilisés par plus de [X] restaurants et entreprises à travers le Québec. Est-ce que des témoignages d'entreprises similaires aideraient? Je peux aussi vous connecter avec un client référence dans votre industrie. Qu'est-ce qui vous aiderait à vous sentir confiant à propos de Pivot?",
            followUpQuestions: [
                "Would you like to speak with a reference customer?",
                "What industry are you in?",
                "What concerns do you have about trying a new solution?"
            ],
            followUpQuestionsFr: [
                "Aimeriez-vous parler avec un client référence?",
                "Dans quelle industrie êtes-vous?",
                "Quelles préoccupations avez-vous à essayer une nouvelle solution?"
            ]
        ),
        Objection(
            category: "Trust",
            objection: "What if it doesn't work for us?",
            objectionFr: "Et si ça ne fonctionne pas pour nous?",
            rebuttal: "Great question - we want you to succeed. That's why we offer a 30-day money-back guarantee. If Pivot doesn't deliver the time savings and efficiency we promise, you get a full refund. We also assign you a dedicated onboarding specialist who stays with you until you're seeing results. What would success look like for you in the first 30 days?",
            rebuttalFr: "Excellente question - nous voulons votre succès. C'est pourquoi nous offrons une garantie de remboursement de 30 jours. Si Pivot ne livre pas les économies de temps et l'efficacité que nous promettons, vous obtenez un remboursement complet. Nous vous assignons aussi un spécialiste d'intégration dédié qui reste avec vous jusqu'à ce que vous voyiez des résultats. À quoi ressemblerait le succès pour vous dans les 30 premiers jours?",
            followUpQuestions: [
                "What would success look like for you?",
                "What's your biggest worry about switching?",
                "Would a pilot program with limited users help?"
            ],
            followUpQuestionsFr: [
                "À quoi ressemblerait le succès pour vous?",
                "Quelle est votre plus grande inquiétude à propos du changement?",
                "Est-ce qu'un programme pilote avec des utilisateurs limités aiderait?"
            ]
        ),
        
        // Decision-Making Objections
        Objection(
            category: "Decision",
            objection: "I need to talk to my partner/owner",
            objectionFr: "Je dois en parler à mon partenaire/propriétaire",
            rebuttal: "Absolutely - this is an important decision. Would it be helpful if I joined that conversation? I can answer any technical or pricing questions directly. Alternatively, I can send you a summary with ROI calculations specific to your business that you can share. What information would be most helpful for that conversation?",
            rebuttalFr: "Absolument - c'est une décision importante. Serait-il utile que je me joigne à cette conversation? Je peux répondre directement à toutes les questions techniques ou de prix. Alternativement, je peux vous envoyer un résumé avec des calculs de ROI spécifiques à votre entreprise que vous pouvez partager. Quelle information serait la plus utile pour cette conversation?",
            followUpQuestions: [
                "Would a joint call be helpful?",
                "What are their main concerns likely to be?",
                "When do you think you'll have that conversation?"
            ],
            followUpQuestionsFr: [
                "Est-ce qu'un appel conjoint serait utile?",
                "Quelles seront probablement leurs principales préoccupations?",
                "Quand pensez-vous avoir cette conversation?"
            ]
        ),
        Objection(
            category: "Decision",
            objection: "I need to think about it",
            objectionFr: "J'ai besoin d'y réfléchir",
            rebuttal: "Of course - it's important to make the right decision. To help you think it through, what specific aspects are you weighing? Is it the cost, the implementation, or something else? I want to make sure you have all the information you need. Also, we do have a promotion ending [date] that I'd hate for you to miss if the timing works out.",
            rebuttalFr: "Bien sûr - c'est important de prendre la bonne décision. Pour vous aider à y réfléchir, quels aspects spécifiques pesez-vous? Est-ce le coût, l'implémentation, ou autre chose? Je veux m'assurer que vous avez toute l'information dont vous avez besoin. Aussi, nous avons une promotion qui se termine [date] que je ne voudrais pas que vous manquiez si le timing fonctionne.",
            followUpQuestionsFr: [
                "Qu'est-ce qui vous ferait dire oui aujourd'hui?",
                "Y a-t-il des questions auxquelles je n'ai pas répondu?",
                "Quel est votre calendrier pour prendre cette décision?"
            ],
            followUpQuestions: [
                "What would make you say yes today?",
                "Are there questions I haven't answered?",
                "What's your timeline for making this decision?"
            ]
        )
    ]
    
    // MARK: - Success Stories
    
    static let successStories: [SuccessStory] = [
        SuccessStory(
            title: "Bistro Le Quartier: 6 Hours Saved Weekly",
            titleFr: "Bistro Le Quartier: 6 heures économisées par semaine",
            industry: "Restaurant",
            companySize: "25 employees",
            description: "A busy Montreal bistro was spending 8+ hours weekly on scheduling using Excel. After switching to Pivot, they reduced scheduling time to under 2 hours. The owner now uses that time on the floor with guests instead of in the back office.",
            descriptionFr: "Un bistro occupé de Montréal passait 8+ heures par semaine sur la planification avec Excel. Après le passage à Pivot, ils ont réduit le temps de planification à moins de 2 heures. Le propriétaire utilise maintenant ce temps sur le plancher avec les clients au lieu d'être dans le bureau.",
            metrics: [
                "Scheduling time": "8h → 2h weekly",
                "Overtime errors": "Reduced by 95%",
                "Employee satisfaction": "Increased 40%",
                "Time savings": "6h/week = $7,800/year"
            ],
            quote: "Pivot paid for itself in the first month. I can't believe I did scheduling in Excel for so long.",
            quoteFr: "Pivot s'est payé dans le premier mois. Je n'arrive pas à croire que j'ai fait la planification dans Excel si longtemps."
        ),
        SuccessStory(
            title: "Café Soleil Chain: Multi-Location Control",
            titleFr: "Chaîne Café Soleil: Contrôle multi-établissements",
            industry: "Coffee Shop Chain",
            companySize: "4 locations, 45 employees",
            description: "Managing 4 café locations with different managers was chaos. Each location had its own scheduling style, overtime was hard to track across locations, and payroll took 2 days. With Pivot, they now have centralized visibility, standardized processes, and same-day payroll.",
            descriptionFr: "Gérer 4 cafés avec différents gestionnaires était chaotique. Chaque établissement avait son propre style de planification, les heures supplémentaires étaient difficiles à suivre entre établissements, et la paie prenait 2 jours. Avec Pivot, ils ont maintenant une visibilité centralisée, des processus standardisés, et la paie le même jour.",
            metrics: [
                "Payroll processing": "2 days → 2 hours",
                "Cross-location visibility": "0% → 100%",
                "Labor cost reduction": "8%",
                "Manager time saved": "12h/week total"
            ],
            quote: "Finally I can see all my locations in one dashboard. Finding coverage across locations is now one click.",
            quoteFr: "Finalement je peux voir tous mes établissements dans un tableau de bord. Trouver de la couverture entre établissements est maintenant un clic."
        ),
        SuccessStory(
            title: "Restaurant Chez Marcel: Compliance Peace of Mind",
            titleFr: "Restaurant Chez Marcel: Tranquillité d'esprit pour la conformité",
            industry: "Fine Dining",
            companySize: "35 employees",
            description: "After receiving a warning from the CNESST about overtime violations, this fine dining restaurant needed a solution that would ensure compliance. Pivot's automatic overtime tracking and scheduling alerts have kept them violation-free for 18 months.",
            descriptionFr: "Après avoir reçu un avertissement de la CNESST concernant des violations d'heures supplémentaires, ce restaurant gastronomique avait besoin d'une solution pour assurer la conformité. Le suivi automatique des heures supplémentaires et les alertes de planification de Pivot les ont gardés sans violation depuis 18 mois.",
            metrics: [
                "Compliance violations": "3/year → 0",
                "Potential fines avoided": "$15,000+",
                "Overtime tracking accuracy": "100%",
                "Audit preparation time": "2 days → 30 minutes"
            ],
            quote: "The automatic compliance alerts have saved us from costly mistakes. Worth every penny for the peace of mind.",
            quoteFr: "Les alertes de conformité automatiques nous ont sauvés d'erreurs coûteuses. Ça vaut chaque sou pour la tranquillité d'esprit."
        ),
        SuccessStory(
            title: "Bar Le Social: Tips Transparency",
            titleFr: "Bar Le Social: Transparence des pourboires",
            industry: "Bar/Nightclub",
            companySize: "20 employees",
            description: "Staff disputes about tip distribution were causing turnover. The manual tip pooling system was error-prone and nobody trusted it. Pivot's transparent tip management system with digital records eliminated disputes and improved retention.",
            descriptionFr: "Les disputes du personnel sur la distribution des pourboires causaient du roulement. Le système manuel de mise en commun des pourboires était sujet aux erreurs et personne ne lui faisait confiance. Le système de gestion des pourboires transparent de Pivot avec des enregistrements numériques a éliminé les disputes et amélioré la rétention.",
            metrics: [
                "Staff turnover": "Reduced 50%",
                "Tip disputes": "Weekly → Zero",
                "Tip calculation time": "45min → 5min nightly",
                "Employee trust score": "Up 60%"
            ],
            quote: "My bartenders finally trust the tip-out. No more arguments at the end of the night.",
            quoteFr: "Mes barmans font enfin confiance au partage des pourboires. Plus de disputes à la fin de la soirée."
        ),
        SuccessStory(
            title: "Boulangerie Artisan: Payroll Simplicity",
            titleFr: "Boulangerie Artisan: Simplicité de la paie",
            industry: "Bakery",
            companySize: "12 employees",
            description: "The owner was doing payroll manually, spending a full day every two weeks reconciling timesheets with Excel. Mistakes were common. With Pivot's integrated payroll, payroll now takes 30 minutes and errors have been eliminated.",
            descriptionFr: "Le propriétaire faisait la paie manuellement, passant une journée complète aux deux semaines à réconcilier les feuilles de temps avec Excel. Les erreurs étaient fréquentes. Avec la paie intégrée de Pivot, la paie prend maintenant 30 minutes et les erreurs ont été éliminées.",
            metrics: [
                "Payroll time": "8h → 30min bi-weekly",
                "Payroll errors": "3-4/month → 0",
                "Employee complaints": "Reduced 90%",
                "Annual time savings": "195 hours"
            ],
            quote: "I used to dread payroll day. Now it's done before my morning coffee gets cold.",
            quoteFr: "Je redoutais le jour de la paie. Maintenant c'est fait avant que mon café du matin refroidisse."
        )
    ]
    
    // MARK: - Integrations
    
    static let integrations: [Integration] = [
        Integration(
            name: "Clover",
            category: "POS",
            description: "Real-time sales integration with Clover POS. Automatic labor cost tracking, demand forecasting, and schedule optimization based on sales patterns.",
            descriptionFr: "Intégration des ventes en temps réel avec Clover POS. Suivi automatique des coûts de main-d'œuvre, prévision de la demande et optimisation des horaires basée sur les patterns de ventes.",
            setupTime: "15 minutes",
            features: [
                "Real-time sales data sync",
                "Labor vs sales dashboard",
                "Demand-based scheduling suggestions",
                "Historical sales pattern analysis",
                "Peak hour identification"
            ]
        ),
        Integration(
            name: "Lightspeed",
            category: "POS",
            description: "Deep integration with Lightspeed Restaurant and Retail. Sync employee roles, track sales performance, and optimize staffing levels automatically.",
            descriptionFr: "Intégration profonde avec Lightspeed Restaurant et Retail. Synchronisez les rôles des employés, suivez la performance des ventes et optimisez les niveaux de personnel automatiquement.",
            setupTime: "20 minutes",
            features: [
                "Employee role sync",
                "Sales performance tracking by employee",
                "Automatic schedule optimization",
                "Inventory-based staffing alerts",
                "Multi-location data aggregation"
            ]
        ),
        Integration(
            name: "Square",
            category: "POS",
            description: "Seamless connection to Square POS for restaurants and retail. Sync employee data, track tips, and align schedules with sales forecasts.",
            descriptionFr: "Connexion fluide à Square POS pour restaurants et commerce de détail. Synchronisez les données employés, suivez les pourboires et alignez les horaires avec les prévisions de ventes.",
            setupTime: "10 minutes",
            features: [
                "One-click employee sync",
                "Tip tracking and distribution",
                "Sales forecast integration",
                "Labor cost percentage alerts",
                "Shift performance metrics"
            ]
        ),
        Integration(
            name: "Maitre'D",
            category: "POS",
            description: "Full integration with Maitre'D POS, popular in Quebec restaurants. Native support for Quebec-specific features including tip declaration.",
            descriptionFr: "Intégration complète avec le POS Maitre'D, populaire dans les restaurants québécois. Support natif pour les fonctionnalités spécifiques au Québec incluant la déclaration des pourboires.",
            setupTime: "25 minutes",
            features: [
                "Native Quebec tip declaration",
                "Real-time table management sync",
                "Server section optimization",
                "Tip pooling automation",
                "Revenu Québec compliant reporting"
            ]
        ),
        Integration(
            name: "QuickBooks",
            category: "Accounting",
            description: "Export payroll and labor data directly to QuickBooks. Automatic journal entries, payroll sync, and financial reporting integration.",
            descriptionFr: "Exportez les données de paie et de main-d'œuvre directement vers QuickBooks. Entrées de journal automatiques, synchronisation de la paie et intégration des rapports financiers.",
            setupTime: "15 minutes",
            features: [
                "Automatic payroll journal entries",
                "Labor cost categorization",
                "Employee data sync",
                "Tax liability tracking",
                "Custom chart of accounts mapping"
            ]
        ),
        Integration(
            name: "Ceridian Dayforce",
            category: "HCM",
            description: "Enterprise integration with Ceridian Dayforce for larger organizations. Bi-directional employee sync and advanced HR data sharing.",
            descriptionFr: "Intégration entreprise avec Ceridian Dayforce pour les plus grandes organisations. Synchronisation bidirectionnelle des employés et partage de données RH avancé.",
            setupTime: "Custom implementation",
            features: [
                "Bi-directional employee sync",
                "Benefits data integration",
                "Advanced HR workflows",
                "Custom field mapping",
                "SSO authentication"
            ]
        )
    ]
    
    // MARK: - Quick Reference Cards
    
    struct QuickReference {
        static let elevatorPitch = """
        Pivot is the workforce management platform built for Quebec businesses. We handle scheduling, \
        time tracking, tips, and payroll - all compliant with Quebec labor laws. Our clients typically \
        save 6+ hours per week and see ROI within 60 days.
        """
        
        static let elevatorPitchFr = """
        Pivot est la plateforme de gestion de main-d'œuvre conçue pour les entreprises québécoises. \
        Nous gérons la planification, le suivi du temps, les pourboires et la paie - le tout conforme \
        aux lois du travail du Québec. Nos clients économisent typiquement 6+ heures par semaine et \
        voient un ROI en 60 jours.
        """
        
        static let keyDifferentiators = [
            "Quebec-first: Built for Quebec labor laws, not adapted from US",
            "All-in-one: Scheduling, time, tips, payroll in one platform",
            "POS integration: Real-time sales data, not just basic sync",
            "Tips management: Complete solution including Revenu Québec compliance",
            "Local support: Quebec-based team, French-first support"
        ]
        
        static let keyDifferentiatorsFr = [
            "Québec d'abord: Conçu pour les lois du Québec, pas adapté des US",
            "Tout-en-un: Planification, temps, pourboires, paie sur une plateforme",
            "Intégration POS: Données de ventes en temps réel, pas juste sync de base",
            "Gestion des pourboires: Solution complète incluant conformité Revenu Québec",
            "Support local: Équipe basée au Québec, support en français d'abord"
        ]
        
        static let idealCustomerProfile = """
        - Restaurants, bars, cafés, retail stores in Quebec
        - 10-200 employees
        - Using manual scheduling (Excel, paper) or basic tools
        - Pain points: time spent scheduling, compliance concerns, tip disputes
        - Has a POS system (Clover, Lightspeed, Square, Maitre'D)
        """
        
        static let idealCustomerProfileFr = """
        - Restaurants, bars, cafés, magasins de détail au Québec
        - 10-200 employés
        - Utilisant la planification manuelle (Excel, papier) ou outils de base
        - Points de douleur: temps passé sur la planification, préoccupations de conformité, disputes de pourboires
        - A un système POS (Clover, Lightspeed, Square, Maitre'D)
        """
        
        static let discoveryQuestions = [
            "How do you currently create your schedules?",
            "How many hours per week do you spend on scheduling?",
            "How do you handle last-minute callouts?",
            "Have you had any issues with overtime compliance?",
            "How do you manage tip distribution?",
            "What POS system do you use?",
            "How do you currently process payroll?",
            "What's your biggest staffing challenge?"
        ]
        
        static let discoveryQuestionsFr = [
            "Comment créez-vous vos horaires actuellement?",
            "Combien d'heures par semaine passez-vous sur la planification?",
            "Comment gérez-vous les absences de dernière minute?",
            "Avez-vous eu des problèmes de conformité aux heures supplémentaires?",
            "Comment gérez-vous la distribution des pourboires?",
            "Quel système POS utilisez-vous?",
            "Comment traitez-vous la paie actuellement?",
            "Quel est votre plus grand défi de personnel?"
        ]
    }
    
    // MARK: - ROI Calculator Helpers
    
    struct ROICalculator {
        /// Calculate estimated monthly savings
        static func calculateMonthlySavings(
            employeeCount: Int,
            currentSchedulingHoursPerWeek: Double,
            managerHourlyRate: Double,
            averageOvertimeErrorsPerMonth: Int,
            averageOvertimeErrorCost: Double
        ) -> ROIResult {
            // Scheduling time savings (80% reduction)
            let schedulingSavingsPerMonth = currentSchedulingHoursPerWeek * 0.8 * 4.33 * managerHourlyRate
            
            // Overtime error savings (95% reduction)
            let overtimeSavingsPerMonth = Double(averageOvertimeErrorsPerMonth) * 0.95 * averageOvertimeErrorCost
            
            // Estimated monthly cost (Professional tier)
            let monthlyCost = Double(employeeCount) * 4.0
            
            let totalSavings = schedulingSavingsPerMonth + overtimeSavingsPerMonth
            let netSavings = totalSavings - monthlyCost
            let roiPercentage = (netSavings / monthlyCost) * 100
            
            return ROIResult(
                monthlyCost: monthlyCost,
                schedulingSavings: schedulingSavingsPerMonth,
                overtimeSavings: overtimeSavingsPerMonth,
                totalSavings: totalSavings,
                netMonthlySavings: netSavings,
                roiPercentage: roiPercentage,
                paybackDays: netSavings > 0 ? Int(30 * monthlyCost / totalSavings) : 0
            )
        }
        
        struct ROIResult {
            let monthlyCost: Double
            let schedulingSavings: Double
            let overtimeSavings: Double
            let totalSavings: Double
            let netMonthlySavings: Double
            let roiPercentage: Double
            let paybackDays: Int
            
            var summary: String {
                """
                Monthly Pivot Cost: $\(String(format: "%.2f", monthlyCost))
                Scheduling Time Savings: $\(String(format: "%.2f", schedulingSavings))
                Overtime Error Savings: $\(String(format: "%.2f", overtimeSavings))
                Total Monthly Savings: $\(String(format: "%.2f", totalSavings))
                Net Monthly Benefit: $\(String(format: "%.2f", netMonthlySavings))
                ROI: \(String(format: "%.0f", roiPercentage))%
                Payback Period: \(paybackDays) days
                """
            }
            
            var summaryFr: String {
                """
                Coût mensuel Pivot: \(String(format: "%.2f", monthlyCost)) $
                Économies temps planification: \(String(format: "%.2f", schedulingSavings)) $
                Économies erreurs heures sup.: \(String(format: "%.2f", overtimeSavings)) $
                Économies mensuelles totales: \(String(format: "%.2f", totalSavings)) $
                Bénéfice mensuel net: \(String(format: "%.2f", netMonthlySavings)) $
                ROI: \(String(format: "%.0f", roiPercentage))%
                Période de récupération: \(paybackDays) jours
                """
            }
        }
    }
}
