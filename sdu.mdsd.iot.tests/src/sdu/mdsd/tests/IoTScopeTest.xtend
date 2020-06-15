package sdu.mdsd.tests

import org.junit.jupiter.api.Test
import com.google.inject.Inject
import org.junit.jupiter.api.^extension.ExtendWith
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import sdu.mdsd.ioT.Model
import sdu.mdsd.ioT.IoTPackage
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import static extension org.junit.Assert.assertEquals
import org.eclipse.xtext.scoping.IScopeProvider
import java.util.List

@ExtendWith(InjectionExtension)
@InjectWith(IoTInjectorProvider)
class IoTScopeTest {
	
	@Inject extension ParseHelper<Model>
	@Inject extension IScopeProvider
	
	@Test
	def void testExportedEObjectDescriptions() {
		val model = '''
		abstract edge device SuperDevice1 {
			var basevar1 = 123
		}
		
		abstract edge device SuperDevice2 extends SuperDevice1 {
			var basevar2 = 223
		}
		
		abstract edge device SuperDevice3 {
			var basevar3 = 323
		}
		
		edge device SubDevice extends SuperDevice2, SuperDevice3 {
			var subvar = 23
		}
		'''.parse
		
		val subdevice = model.devices.filter[d | d.name == "SubDevice"].get(0)
		val superdevice1 = model.devices.filter[d | d.name == "SuperDevice1"].get(0)
		val superdevice2 = model.devices.filter[d | d.name == "SuperDevice2"].get(0)
		val superdevice3 = model.devices.filter[d | d.name == "SuperDevice3"].get(0)
		
		val eReferencesToCheck = newArrayList(
			IoTPackage.eINSTANCE.varAccess_VariableName,
			IoTPackage.eINSTANCE.readVariable_Value,
			IoTPackage.eINSTANCE.toVar_Variable,
			IoTPackage.eINSTANCE.externalOf_Target,
			IoTPackage.eINSTANCE.itemVariable_Value
		)
		
		subdevice.program.assertScope(eReferencesToCheck, "basevar3, basevar1, basevar2, subvar")
		superdevice1.program.assertScope(eReferencesToCheck, "basevar1")
		superdevice2.program.assertScope(eReferencesToCheck, "basevar1, basevar2")
		superdevice3.program.assertScope(eReferencesToCheck, "basevar3")
		
	}
	
	def private assertScope(EObject context, List<EReference> references, CharSequence expected) {
		for (ref : references) {
			context.assertScope(ref, expected)
		}
	}
	
	def private assertScope(EObject context, EReference reference, CharSequence expected) {
		val scope = context.getScope(reference).allElements.map[name].join(", ")
		expected.toString.assertEquals(scope)
	}
}