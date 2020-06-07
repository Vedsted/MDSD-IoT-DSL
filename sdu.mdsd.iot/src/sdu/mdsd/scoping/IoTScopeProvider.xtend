/*
 * generated by Xtext 2.20.0
 */
package sdu.mdsd.scoping

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import sdu.mdsd.ioT.IoTPackage
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes
import sdu.mdsd.ioT.EdgeDevice
import sdu.mdsd.ioT.FogDevice
import sdu.mdsd.ioT.CloudDevice
import sdu.mdsd.ioT.Program
import com.google.inject.Inject
import sdu.mdsd.utils.IoTUtils

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class IoTScopeProvider extends AbstractIoTScopeProvider {
	
	@Inject extension IoTUtils

	override getScope(EObject context, EReference reference) {
		// These are the cases where we can ref a variable/list from a super type
		if (reference == IoTPackage.eINSTANCE.varAccess_VariableName ||
			reference == IoTPackage.eINSTANCE.readVariable_Value ||
			reference == IoTPackage.eINSTANCE.toVar_Variable ||
			reference == IoTPackage.eINSTANCE.externalOf_Target ||
			reference == IoTPackage.eINSTANCE.itemVariable_Value) {
			scopeForVariable(context)
		} else {
			// Return the default scope
			super.getScope(context, reference)
		}
	}
	
	def protected IScope scopeForVariable(EObject context) {
		val container = context.eContainer
		
		switch container {
			EdgeDevice | FogDevice | CloudDevice: {
				println("Container is a Device")
				
				// Search for Variables within the whole hierarchy
				val currentScopeVars = container.deviceHierarchyVariables
				return Scopes.scopeFor(currentScopeVars)
			}
			Program: {
				println("Container is a Program")
				return Scopes.scopeFor(container.variables,
										scopeForVariable(container)) // outer scope, i.e. super types
			}
			
			default: {
				println("Container is default")
				scopeForVariable(container)
			}
		}
	}	
}
