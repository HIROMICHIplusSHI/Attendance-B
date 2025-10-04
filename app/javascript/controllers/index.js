// Import and register all your controllers from the importmap under controllers/*

import { application } from "./application"

// Import and register modal controller
import ModalController from "controllers/modal_controller"
application.register("modal", ModalController)
