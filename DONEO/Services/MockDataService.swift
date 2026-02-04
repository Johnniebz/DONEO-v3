import Foundation
import Observation

// MARK: - Activity Model

enum ActivityType: String {
    case taskAssigned = "assigned"
    case taskCompleted = "completed"
    case taskReopened = "reopened"
    case taskCreated = "created"
    case messageSent = "message"
}

struct Activity: Identifiable {
    let id: UUID
    let type: ActivityType
    let timestamp: Date
    let actorId: UUID      // Who performed the action
    let actorName: String
    let projectId: UUID
    let projectName: String
    let taskId: UUID?
    let taskTitle: String?
    let messagePreview: String?

    init(
        id: UUID = UUID(),
        type: ActivityType,
        timestamp: Date = Date(),
        actor: User,
        project: Project,
        task: DONEOTask? = nil,
        messagePreview: String? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.actorId = actor.id
        self.actorName = actor.name
        self.projectId = project.id
        self.projectName = project.name
        self.taskId = task?.id
        self.taskTitle = task?.title
        self.messagePreview = messagePreview
    }

    var description: String {
        let firstName = actorName.components(separatedBy: " ").first ?? actorName
        switch type {
        case .taskAssigned:
            return "\(firstName) te asignó: \(taskTitle ?? "una tarea")"
        case .taskCompleted:
            return "\(firstName) completó: \(taskTitle ?? "una tarea")"
        case .taskReopened:
            return "\(firstName) reabrió: \(taskTitle ?? "una tarea")"
        case .taskCreated:
            return "\(firstName) creó: \(taskTitle ?? "una tarea")"
        case .messageSent:
            return "\(firstName): \(messagePreview ?? "envió un mensaje")"
        }
    }

    var icon: String {
        switch type {
        case .taskAssigned: return "person.badge.plus"
        case .taskCompleted: return "checkmark.circle.fill"
        case .taskReopened: return "arrow.uturn.backward.circle"
        case .taskCreated: return "plus.circle.fill"
        case .messageSent: return "message.fill"
        }
    }

    var iconColor: String {
        switch type {
        case .taskAssigned: return "blue"
        case .taskCompleted: return "green"
        case .taskReopened: return "orange"
        case .taskCreated: return "purple"
        case .messageSent: return "blue"
        }
    }
}

// MARK: - Mock Data Service

@Observable
final class MockDataService {
    static let shared = MockDataService()

    private init() {
        _currentUser = Self.allUsers[0]
    }

    // MARK: - Mock Users

    static let allUsers: [User] = [
        User(name: "Alejandro García", phoneNumber: "+34 612-345-678"),
        User(name: "María López", phoneNumber: "+34 623-456-789"),
        User(name: "Carlos Rodríguez", phoneNumber: "+34 634-567-890"),
        User(name: "Sofía Martínez", phoneNumber: "+34 645-678-901"),
        User(name: "Miguel Fernández", phoneNumber: "+34 656-789-012")
    ]

    private var _currentUser: User

    var currentUser: User {
        get { _currentUser }
        set { _currentUser = newValue }
    }

    var mockUsers: [User] {
        Self.allUsers
    }

    func switchUser(to user: User) {
        _currentUser = user
    }

    var currentUserIndex: Int {
        Self.allUsers.firstIndex(where: { $0.id == currentUser.id }) ?? 0
    }

    // MARK: - Projects (shared data store)

    var projects: [Project] = []

    func loadProjects() {
        if projects.isEmpty {
            projects = createMockProjects()
        }
    }

    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        }
    }

    // MARK: - Activities (timeline)

    var activities: [Activity] = []

    func addActivity(type: ActivityType, actor: User, project: Project, task: DONEOTask? = nil, messagePreview: String? = nil) {
        let activity = Activity(
            type: type,
            actor: actor,
            project: project,
            task: task,
            messagePreview: messagePreview
        )
        activities.insert(activity, at: 0)
    }

    // Activities for current user (excludes own actions)
    var activitiesForCurrentUser: [Activity] {
        activities.filter { $0.actorId != currentUser.id }
    }

    func loadMockActivities() {
        guard activities.isEmpty else { return }
        let maria = Self.allUsers[1]
        let carlos = Self.allUsers[2]
        let sofia = Self.allUsers[3]

        guard let project1 = projects.first,
              let project2 = projects.dropFirst().first else { return }

        // Create some mock activities
        activities = [
            Activity(type: .messageSent, timestamp: Date().addingTimeInterval(-300), actor: maria, project: project1, messagePreview: "¿Puedes revisar las medidas?"),
            Activity(type: .taskCompleted, timestamp: Date().addingTimeInterval(-1800), actor: carlos, project: project1, task: project1.tasks.first { $0.status == .done }),
            Activity(type: .taskAssigned, timestamp: Date().addingTimeInterval(-3600), actor: sofia, project: project2, task: project2.tasks.first),
            Activity(type: .taskCreated, timestamp: Date().addingTimeInterval(-7200), actor: maria, project: project1, task: project1.tasks.first),
            Activity(type: .messageSent, timestamp: Date().addingTimeInterval(-86400), actor: carlos, project: project1, messagePreview: "Terminaré los azulejos mañana"),
        ]
    }

    func project(withId id: UUID) -> Project? {
        projects.first { $0.id == id }
    }

    // MARK: - Mock Projects

    private func createMockProjects() -> [Project] {
        let alejandro = Self.allUsers[0]
        let maria = Self.allUsers[1]
        let carlos = Self.allUsers[2]
        let sofia = Self.allUsers[3]
        let miguel = Self.allUsers[4]

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)
        let nextWeek = Calendar.current.date(byAdding: .day, value: 5, to: today)

        // Create sample messages for projects
        let project1Messages: [Message] = [
            Message(
                content: "Empecemos a pedir los materiales de cocina esta semana",
                sender: alejandro,
                timestamp: Calendar.current.date(byAdding: .hour, value: -5, to: today) ?? today,
                isFromCurrentUser: true
            ),
            Message(
                content: "Hoy conseguiré los presupuestos de los proveedores",
                sender: maria,
                timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: today) ?? today,
                isFromCurrentUser: false
            ),
            Message(
                content: "¿Puedes revisar las medidas?",
                sender: maria,
                timestamp: Calendar.current.date(byAdding: .minute, value: -30, to: today) ?? today,
                isFromCurrentUser: false
            )
        ]

        let project2Messages: [Message] = [
            Message(
                content: "Inspección final programada para mañana",
                sender: alejandro,
                timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: today) ?? today,
                isFromCurrentUser: true
            ),
            Message(
                content: "Prepararé la lista de verificación",
                sender: sofia,
                timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: today) ?? today,
                isFromCurrentUser: false
            )
        ]

        let project3Messages: [Message] = [
            Message(
                content: "Las unidades de climatización deben pedirse antes del viernes",
                sender: miguel,
                timestamp: Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today,
                isFromCurrentUser: false
            ),
            Message(
                content: "Entendido, coordinaré con el proveedor",
                sender: alejandro,
                timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: today) ?? today,
                isFromCurrentUser: true
            ),
            Message(
                content: "Reunión de revisión de planos mañana a las 10am",
                sender: maria,
                timestamp: Calendar.current.date(byAdding: .minute, value: -45, to: today) ?? today,
                isFromCurrentUser: false
            )
        ]

        // Create tasks with known IDs for notification tracking
        let task1_1 = DONEOTask(
            title: "Pedir materiales para la cocina",
            assignees: [maria],
            status: .pending,
            dueDate: today,
            subtasks: [
                Subtask(title: "Obtener presupuestos de 3 proveedores", isDone: true, assignees: [maria], createdBy: carlos),
                Subtask(title: "Comparar precios y calidad", isDone: true, assignees: [maria, carlos], createdBy: carlos),
                Subtask(title: "Realizar pedido con el proveedor seleccionado", isDone: false, assignees: [maria], createdBy: carlos),
                Subtask(title: "Confirmar fecha de entrega", isDone: false, createdBy: carlos)
            ],
            attachments: [
                Attachment(
                    type: .document,
                    category: .reference,
                    fileName: "Lista_Materiales_Cocina.pdf",
                    fileSize: 245_000,
                    uploadedBy: carlos
                ),
                Attachment(
                    type: .image,
                    category: .reference,
                    fileName: "Plano_Cocina.jpg",
                    fileSize: 1_200_000,
                    uploadedBy: carlos
                )
            ],
            notes: """
            Contacto: Leroy Merlin Pro
            Teléfono: (91) 123-4567
            Cuenta #: PRO-2847593

            Materiales necesarios:
            - 24 m² azulejos cerámicos (Toscana Beige)
            - 3 sacos de cemento cola
            - Lechada (color Arena)
            - Crucetas de 6mm

            Dirección de entrega:
            Calle Mayor 742, Centro
            """,
            createdBy: carlos
        )
        let task1_2 = DONEOTask(
            title: "Programar inspección eléctrica",
            assignees: [alejandro],
            status: .pending,
            dueDate: tomorrow,
            subtasks: [
                Subtask(title: "Llamar a la oficina del inspector", isDone: true, assignees: [alejandro], createdBy: maria),
                Subtask(title: "Preparar documentación", isDone: false, assignees: [carlos, alejandro], createdBy: maria),
                Subtask(title: "Despejar acceso al cuadro eléctrico", isDone: false, createdBy: maria)
            ],
            notes: """
            Inspector Municipal: Roberto Martínez
            Oficina: (91) 234-5678

            Documentos requeridos:
            - Permiso #EL-2024-0847
            - Planos eléctricos (revisados)
            - Copia licencia de contratista

            El inspector prefiere citas por la mañana (8-10am)
            """,
            createdBy: maria,
            acknowledgedBy: [alejandro.id] // Alejandro has accepted this task
        )
        let task1_3 = DONEOTask(title: "Completar azulejos del baño", assignees: [carlos], status: .done, createdBy: alejandro)

        // New task for Alejandro - painting
        let task1_4_paint = DONEOTask(
            title: "Pintar paredes del salón",
            assignees: [alejandro, carlos],
            status: .pending,
            dueDate: tomorrow,
            subtasks: [
                Subtask(title: "Comprar materiales de pintura", isDone: true, assignees: [carlos], createdBy: maria),
                Subtask(title: "Preparar paredes y poner cinta", isDone: false, assignees: [alejandro], createdBy: maria),
                Subtask(title: "Aplicar primera capa", isDone: false, assignees: [alejandro, carlos], createdBy: maria),
                Subtask(title: "Aplicar segunda capa", isDone: false, createdBy: maria)
            ],
            notes: "Color: Blanco Nube OC-130\nSe necesitan 8 litros",
            createdBy: maria
            // Not acknowledged by Alejandro yet - NEW task
        )

        let task1_5 = DONEOTask(
            title: "Instalar ventanas nuevas",
            assignees: [alejandro],
            status: .pending,
            dueDate: nextWeek,
            subtasks: [
                Subtask(title: "Medir todos los marcos de ventanas", isDone: false, assignees: [carlos], createdBy: carlos),
                Subtask(title: "Pedir ventanas a medida", isDone: false, assignees: [maria, alejandro], createdBy: carlos),
                Subtask(title: "Retirar ventanas antiguas", isDone: false, createdBy: carlos),
                Subtask(title: "Instalar ventanas nuevas", isDone: false, createdBy: carlos),
                Subtask(title: "Sellar y aislar", isDone: false, createdBy: carlos)
            ],
            attachments: [
                Attachment(
                    type: .document,
                    category: .reference,
                    fileName: "Especificaciones_Ventanas.pdf",
                    fileSize: 890_000,
                    uploadedBy: carlos
                ),
                Attachment(
                    type: .image,
                    category: .reference,
                    fileName: "Foto_Medidas_Ventanas.jpg",
                    fileSize: 2_400_000,
                    uploadedBy: carlos
                ),
                Attachment(
                    type: .image,
                    category: .work,
                    fileName: "Ventana_Antigua_Retirada.jpg",
                    fileSize: 1_800_000,
                    uploadedBy: alejandro,
                    caption: "Primera ventana retirada con éxito"
                )
            ],
            notes: """
            Proveedor de ventanas: Cristalería Vista Clara
            Comercial: Javier Wong
            Teléfono: (91) 345-6789

            Especificaciones: Doble cristal, Bajo emisivo, Relleno de argón
            Color del marco: PVC blanco

            Plazo de entrega: 2-3 semanas para medidas personalizadas
            """,
            createdBy: carlos,
            acknowledgedBy: [alejandro.id] // Alejandro acknowledged
        )

        // More tasks for Downtown Renovation
        let task1_6 = DONEOTask(
            title: "Reparar grifo con fuga en la cocina",
            assignees: [alejandro],
            status: .pending,
            dueDate: today,
            notes: "El cliente reportó fuga bajo el fregadero. Revisar sifón y conexiones.",
            createdBy: maria,
            acknowledgedBy: [alejandro.id]
        )

        let task1_7 = DONEOTask(
            title: "Instalar tiradores de armarios",
            assignees: [alejandro],
            status: .pending,
            subtasks: [
                Subtask(title: "Desempaquetar todos los tiradores", isDone: true, assignees: [alejandro], createdBy: carlos),
                Subtask(title: "Marcar posiciones de taladro", isDone: true, assignees: [alejandro], createdBy: carlos),
                Subtask(title: "Instalar tiradores en armarios superiores", isDone: false, createdBy: carlos),
                Subtask(title: "Instalar tiradores en armarios inferiores", isDone: false, createdBy: carlos),
                Subtask(title: "Instalar tiradores de cajones", isDone: false, createdBy: carlos)
            ],
            createdBy: carlos,
            acknowledgedBy: [alejandro.id]
        )

        let task2_1 = DONEOTask(
            title: "Inspección final",
            assignees: [alejandro],
            status: .pending,
            dueDate: yesterday,
            subtasks: [
                Subtask(title: "Revisar todas las habitaciones", isDone: true, assignees: [alejandro], createdBy: sofia),
                Subtask(title: "Probar enchufes eléctricos", isDone: true, createdBy: sofia),
                Subtask(title: "Probar fontanería", isDone: false, assignees: [alejandro, sofia], createdBy: sofia),
                Subtask(title: "Documentar cualquier incidencia", isDone: false, assignees: [sofia], createdBy: sofia)
            ],
            attachments: [
                Attachment(
                    type: .document,
                    category: .reference,
                    fileName: "Lista_Verificacion_Inspeccion.pdf",
                    fileSize: 156_000,
                    uploadedBy: sofia
                ),
                Attachment(
                    type: .image,
                    category: .work,
                    fileName: "Salon_Completado.jpg",
                    fileSize: 2_100_000,
                    uploadedBy: alejandro,
                    caption: "Inspección del salón aprobada"
                ),
                Attachment(
                    type: .image,
                    category: .work,
                    fileName: "Prueba_Enchufes_Cocina.jpg",
                    fileSize: 1_900_000,
                    uploadedBy: alejandro,
                    caption: "Todos los enchufes de cocina funcionando"
                )
            ],
            notes: """
            Propiedad: Residencia Sánchez
            Dirección: Avenida del Roble 1847, Riverside

            Contacto del cliente: Sr. y Sra. Sánchez
            Teléfono: (91) 456-7890

            Código de puerta: 4523
            Código del candado: 1234

            ¡Tomar fotos de cualquier incidencia encontrada!
            """,
            createdBy: sofia,
            acknowledgedBy: [alejandro.id] // Alejandro has accepted this task
        )
        let task2_2 = DONEOTask(title: "Reparar puerta del garaje", assignees: [sofia], status: .done, createdBy: alejandro)

        // New tasks for Smith Residence
        let task2_3 = DONEOTask(
            title: "Retocar pintura del pasillo",
            assignees: [alejandro],
            status: .pending,
            dueDate: today,
            notes: "Pequeños roces cerca de la puerta principal. Código de pintura: SW7015 Gris Reposo",
            createdBy: sofia
            // NEW - not acknowledged
        )

        let task2_4 = DONEOTask(
            title: "Cambiar pilas de detectores de humo",
            assignees: [alejandro, sofia],
            status: .pending,
            subtasks: [
                Subtask(title: "Revisar detectores del piso superior", isDone: false, assignees: [alejandro], createdBy: sofia),
                Subtask(title: "Revisar detectores del piso inferior", isDone: false, assignees: [sofia], createdBy: sofia),
                Subtask(title: "Probar todas las alarmas", isDone: false, createdBy: sofia)
            ],
            createdBy: sofia,
            acknowledgedBy: [alejandro.id, sofia.id]
        )

        let task3_1 = DONEOTask(
            title: "Revisar planos",
            assignees: [miguel],
            status: .pending,
            dueDate: today,
            subtasks: [
                Subtask(title: "Revisar planos estructurales", isDone: true, assignees: [miguel], createdBy: alejandro),
                Subtask(title: "Verificar distribución eléctrica", isDone: false, assignees: [alejandro, miguel], createdBy: alejandro),
                Subtask(title: "Verificar rutas de fontanería", isDone: false, assignees: [maria], createdBy: alejandro)
            ],
            createdBy: alejandro
        )
        let task3_2 = DONEOTask(
            title: "Pedir unidades de climatización",
            assignees: [maria, alejandro],
            status: .pending,
            dueDate: nextWeek,
            notes: """
            Proveedor: Sistemas de Climatización
            Contacto: Tomás Ruiz
            Teléfono: (91) 567-8901
            Email: tomas@climatizacion.com

            Presupuesto #: CCS-2024-1847
            2x Unidades Carrier 5 toneladas
            Total: 12.450€ (incluye instalación)

            Requiere 50% de depósito para pedir
            """,
            createdBy: miguel,
            acknowledgedBy: [maria.id] // María accepted, but Alejandro hasn't yet - NEW for Alejandro
        )
        let task3_3 = DONEOTask(
            title: "Coordinar con inspector municipal",
            assignees: [alejandro],
            status: .pending,
            notes: """
            Departamento de Urbanismo: (91) 678-9012
            Permiso #: BLD-2024-0293

            Inspecciones necesarias:
            1. Cimentación (APROBADA)
            2. Estructura (APROBADA)
            3. Preinstalación eléctrica (PROGRAMADA)
            4. Preinstalación de fontanería (PENDIENTE)
            5. Inspección final

            Inspector asignado: Carlos Méndez
            """,
            createdBy: maria // María assigned this to Alejandro - NEW task needing acknowledgment
        )
        let task3_4 = DONEOTask(title: "Completar trabajos de cimentación", assignees: [miguel], status: .done, createdBy: alejandro)
        let task3_5 = DONEOTask(title: "Instalar preinstalación de fontanería", assignees: [alejandro], status: .pending, dueDate: tomorrow, createdBy: miguel)

        // More tasks for Office Building
        let task3_6 = DONEOTask(
            title: "Programar vertido de hormigón",
            assignees: [alejandro],
            status: .pending,
            dueDate: nextWeek,
            notes: "Se necesitan 12 metros cúbicos. Coordinar con camión bomba.",
            createdBy: miguel,
            acknowledgedBy: [alejandro.id]
        )

        let task3_7 = DONEOTask(
            title: "Pedir cuadros eléctricos",
            assignees: [alejandro, maria],
            status: .pending,
            dueDate: today,
            subtasks: [
                Subtask(title: "Obtener presupuesto de ElectroPro", isDone: true, assignees: [maria], createdBy: miguel),
                Subtask(title: "Confirmar especificaciones con ingeniero", isDone: false, assignees: [alejandro], createdBy: miguel),
                Subtask(title: "Realizar pedido", isDone: false, createdBy: miguel)
            ],
            createdBy: miguel
            // NEW - Alejandro hasn't acknowledged
        )

        let task3_8 = DONEOTask(
            title: "Actualizar cronograma del proyecto",
            assignees: [alejandro],
            status: .pending,
            notes: "El cliente quiere el calendario revisado antes del viernes",
            createdBy: maria
            // NEW - not acknowledged
        )

        let task4_1 = DONEOTask(title: "Revisar excavadora", assignees: [carlos], status: .done, createdBy: alejandro)
        let task4_2 = DONEOTask(title: "Cambiar brocas de taladro", assignees: [miguel], status: .done, createdBy: alejandro)

        // New tasks for Equipment Maintenance
        let task4_3 = DONEOTask(
            title: "Inspeccionar arneses de seguridad",
            assignees: [alejandro],
            status: .pending,
            dueDate: tomorrow,
            notes: "Inspección anual vencida. Revisar los 8 arneses.",
            createdBy: carlos,
            acknowledgedBy: [alejandro.id]
        )

        let task4_4 = DONEOTask(
            title: "Pedir cuchillas de repuesto",
            assignees: [alejandro, miguel],
            status: .pending,
            subtasks: [
                Subtask(title: "Revisar inventario", isDone: true, assignees: [miguel], createdBy: carlos),
                Subtask(title: "Obtener presupuestos", isDone: false, assignees: [alejandro], createdBy: carlos),
                Subtask(title: "Enviar orden de compra", isDone: false, createdBy: carlos)
            ],
            createdBy: carlos
            // NEW - Alejandro hasn't acknowledged
        )

        let task5_1 = DONEOTask(title: "Enviar factura", assignees: [alejandro], status: .pending, dueDate: yesterday, createdBy: sofia, acknowledgedBy: [alejandro.id])
        let task5_2 = DONEOTask(title: "Programar reunión de seguimiento", assignees: [sofia], status: .pending, dueDate: tomorrow, createdBy: alejandro)

        // More tasks for ABC Corp
        let task5_3 = DONEOTask(
            title: "Preparar documentos de cierre del proyecto",
            assignees: [alejandro],
            status: .pending,
            dueDate: nextWeek,
            subtasks: [
                Subtask(title: "Recopilar garantías", isDone: false, assignees: [alejandro], createdBy: sofia),
                Subtask(title: "Reunir planos finales", isDone: false, createdBy: sofia),
                Subtask(title: "Escribir resumen del proyecto", isDone: false, assignees: [sofia], createdBy: sofia)
            ],
            createdBy: sofia,
            acknowledgedBy: [alejandro.id]
        )

        let task5_4 = DONEOTask(
            title: "Revisar lista de repasos final",
            assignees: [alejandro],
            status: .pending,
            dueDate: today,
            notes: "Quedan 12 puntos pendientes. Visita del cliente a las 14:00.",
            createdBy: sofia
            // NEW - not acknowledged
        )

        // Create mock attachments for projects
        let project1Attachments: [ProjectAttachment] = [
            ProjectAttachment(
                type: .document,
                fileName: "Presupuesto_Materiales_Cocina.pdf",
                fileSize: 245_000,
                uploadedBy: maria,
                uploadedAt: Calendar.current.date(byAdding: .day, value: -3, to: today) ?? today,
                linkedTaskId: task1_1.id
            ),
            ProjectAttachment(
                type: .document,
                fileName: "Comparativa_Proveedores.xlsx",
                fileSize: 128_000,
                uploadedBy: maria,
                uploadedAt: Calendar.current.date(byAdding: .day, value: -2, to: today) ?? today,
                linkedTaskId: task1_1.id
            ),
            ProjectAttachment(
                type: .image,
                fileName: "Medidas_Cocina.jpg",
                fileSize: 3_200_000,
                uploadedBy: carlos,
                uploadedAt: Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today,
                linkedTaskId: task1_1.id
            ),
            ProjectAttachment(
                type: .document,
                fileName: "Permiso_Electrico.pdf",
                fileSize: 89_000,
                uploadedBy: alejandro,
                uploadedAt: Calendar.current.date(byAdding: .hour, value: -5, to: today) ?? today,
                linkedTaskId: task1_2.id
            ),
            ProjectAttachment(
                type: .image,
                fileName: "Azulejos_Baño_Completado.jpg",
                fileSize: 2_800_000,
                uploadedBy: carlos,
                uploadedAt: Calendar.current.date(byAdding: .day, value: -4, to: today) ?? today,
                linkedTaskId: task1_3.id
            ),
            ProjectAttachment(
                type: .document,
                fileName: "Especificaciones_Ventanas.pdf",
                fileSize: 156_000,
                uploadedBy: alejandro,
                uploadedAt: Calendar.current.date(byAdding: .hour, value: -2, to: today) ?? today,
                linkedTaskId: task1_5.id
            )
        ]

        let project2Attachments: [ProjectAttachment] = [
            ProjectAttachment(
                type: .document,
                fileName: "Lista_Verificacion_Inspeccion.pdf",
                fileSize: 67_000,
                uploadedBy: sofia,
                uploadedAt: Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today,
                linkedTaskId: task2_1.id
            ),
            ProjectAttachment(
                type: .image,
                fileName: "Problema_Fontaneria.jpg",
                fileSize: 1_950_000,
                uploadedBy: alejandro,
                uploadedAt: Calendar.current.date(byAdding: .hour, value: -3, to: today) ?? today,
                linkedTaskId: task2_1.id
            ),
            ProjectAttachment(
                type: .image,
                fileName: "Puerta_Garaje_Reparada.jpg",
                fileSize: 2_100_000,
                uploadedBy: sofia,
                uploadedAt: Calendar.current.date(byAdding: .day, value: -2, to: today) ?? today,
                linkedTaskId: task2_2.id
            )
        ]

        let project3Attachments: [ProjectAttachment] = [
            ProjectAttachment(
                type: .document,
                fileName: "Planos_Fase2_v3.pdf",
                fileSize: 4_500_000,
                uploadedBy: miguel,
                uploadedAt: Calendar.current.date(byAdding: .day, value: -5, to: today) ?? today,
                linkedTaskId: task3_1.id
            ),
            ProjectAttachment(
                type: .document,
                fileName: "Presupuesto_Climatizacion.pdf",
                fileSize: 312_000,
                uploadedBy: maria,
                uploadedAt: Calendar.current.date(byAdding: .day, value: -2, to: today) ?? today,
                linkedTaskId: task3_2.id
            ),
            ProjectAttachment(
                type: .document,
                fileName: "Permiso_Municipal_BLD-2024-0293.pdf",
                fileSize: 178_000,
                uploadedBy: alejandro,
                uploadedAt: Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today,
                linkedTaskId: task3_3.id
            ),
            ProjectAttachment(
                type: .image,
                fileName: "Inspeccion_Cimentacion_Aprobada.jpg",
                fileSize: 2_400_000,
                uploadedBy: miguel,
                uploadedAt: Calendar.current.date(byAdding: .day, value: -10, to: today) ?? today,
                linkedTaskId: task3_4.id
            ),
            ProjectAttachment(
                type: .document,
                fileName: "Distribucion_Fontaneria.pdf",
                fileSize: 890_000,
                uploadedBy: alejandro,
                uploadedAt: Calendar.current.date(byAdding: .hour, value: -6, to: today) ?? today,
                linkedTaskId: task3_5.id
            )
        ]

        let project5Attachments: [ProjectAttachment] = [
            ProjectAttachment(
                type: .document,
                fileName: "Factura_ABC-2024-0158.pdf",
                fileSize: 145_000,
                uploadedBy: alejandro,
                uploadedAt: Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today,
                linkedTaskId: task5_1.id
            ),
            ProjectAttachment(
                type: .document,
                fileName: "Resumen_Proyecto.docx",
                fileSize: 234_000,
                uploadedBy: sofia,
                uploadedAt: Calendar.current.date(byAdding: .hour, value: -8, to: today) ?? today
            )
        ]

        return [
            Project(
                name: "Renovación Centro",
                members: [alejandro, maria, carlos],
                tasks: [task1_1, task1_2, task1_3, task1_4_paint, task1_5, task1_6, task1_7],
                messages: project1Messages,
                attachments: project1Attachments,
                unreadTaskIds: [
                    alejandro.id: [task1_1.id, task1_3.id],
                    maria.id: [task1_2.id],
                    carlos.id: [task1_1.id, task1_2.id]
                ],
                lastActivity: Date(),
                lastActivityPreview: "María: ¿Puedes revisar las medidas?"
            ),
            Project(
                name: "Residencia Sánchez",
                members: [alejandro, sofia],
                tasks: [task2_1, task2_2, task2_3, task2_4],
                messages: project2Messages,
                attachments: project2Attachments,
                unreadTaskIds: [:],
                lastActivity: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
                lastActivityPreview: "Completado: Reparar puerta del garaje"
            ),
            Project(
                name: "Edificio de Oficinas - Fase 2",
                members: [alejandro, maria, miguel],
                tasks: [task3_1, task3_2, task3_3, task3_4, task3_5, task3_6, task3_7, task3_8],
                messages: project3Messages,
                attachments: project3Attachments,
                unreadTaskIds: [
                    alejandro.id: [task3_1.id, task3_2.id, task3_4.id, task3_5.id],
                    maria.id: [task3_1.id, task3_3.id, task3_4.id],
                    miguel.id: [task3_2.id, task3_3.id, task3_5.id]
                ],
                lastActivity: Calendar.current.date(byAdding: .minute, value: -30, to: Date()),
                lastActivityPreview: "Nueva tarea: Instalar preinstalación de fontanería"
            ),
            Project(
                name: "Mantenimiento de Equipos",
                members: [alejandro, carlos, miguel],
                tasks: [task4_1, task4_2, task4_3, task4_4],
                messages: [],
                attachments: [],
                unreadTaskIds: [:],
                lastActivity: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                lastActivityPreview: "Completado: Cambiar brocas de taladro"
            ),
            Project(
                name: "Cliente: Corporación ABC",
                members: [alejandro, sofia],
                tasks: [task5_1, task5_2, task5_3, task5_4],
                messages: [],
                attachments: project5Attachments,
                unreadTaskIds: [
                    alejandro.id: [task5_2.id]
                ],
                lastActivity: Calendar.current.date(byAdding: .hour, value: -5, to: Date()),
                lastActivityPreview: "Sofía: La factura está lista para revisión"
            )
        ]
    }
}
