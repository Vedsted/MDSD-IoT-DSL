package sdu.mdsd.tests

import com.google.inject.Inject
import org.eclipse.emf.ecore.EClass
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith
import sdu.mdsd.ioT.IoTPackage
import sdu.mdsd.ioT.Model
import sdu.mdsd.validation.IoTValidator

//@RunWith(XtextRunner)
@ExtendWith(InjectionExtension)
@InjectWith(IoTInjectorProvider)
class CyclicDeclarationValidationTests {
	
	@Inject extension ParseHelper<Model>
	@Inject extension ValidationTestHelper
	
	@Test
	def void cyclicMultiInheritance() {
		'''
			abstract abs1 {}
			
			abstract abs2 : abs1 {}
			
			iot test : abs1, abs2 {}
		'''.parse.assertCyclicDeclaration(IoTPackage.eINSTANCE.ioTDevice, 'test')
	}
	
	@Test
	def void cyclicComplexMultiInheritance() {
		'''
			abstract abs1 {}
			abstract abs2 : abs1 {}
			abstract abs3 : abs1 {}
			controller test : abs3, abs2 {}
		'''.parse.assertCyclicDeclaration(IoTPackage.eINSTANCE.controllerDevice, 'test')
	}
	
	@Test
	def void selfCyclicDeclaration() {
		'''
			abstract abs1 : abs1 {}
		'''.parse.assertCyclicDeclaration(IoTPackage.eINSTANCE.abstractDevice, 'abs1')
	}
	
	@Test
	def void cyclicDeclaration() {
		'''
			abstract abs1 : abs2 {}
			abstract abs2 : abs1 {}
		'''.parse.assertCyclicDeclaration(IoTPackage.eINSTANCE.abstractDevice, 'abs1') // error is found in both abs 1 and 2, but 1 is first
	}
	
	private def assertCyclicDeclaration(Model m, EClass type, String name) {
		m.assertError(
			type, 
			IoTValidator.CYCLIC_DECLARATION,
			"Cyclic declaration found in device: '" + name + "'"
		)
	}
	
	@Test
	def void noCyclicDeclaration() {
		'''
			abstract abs1 {}
			abstract abs2 {}
			abstract abs3 : abs2 {}
			iot test : abs1, abs3 {}
		'''.parse.assertNoErrors
	}
}