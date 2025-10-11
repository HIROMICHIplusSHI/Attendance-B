// Import and register all your controllers from the importmap under controllers/*

import { application } from "./application"

// Import and register modal controllers
import ModalController from "controllers/modal_controller"
import FormModalController from "controllers/form_modal_controller"
import BulkModalController from "controllers/bulk_modal_controller"

application.register("modal", ModalController)
application.register("form-modal", FormModalController)
application.register("bulk-modal", BulkModalController)
