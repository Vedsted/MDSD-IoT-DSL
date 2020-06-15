package sdu.mdsd.tests

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.junit.jupiter.api.^extension.ExtendWith
import sdu.mdsd.ioT.Model
import org.junit.jupiter.api.Test
import sdu.mdsd.ioT.IoTPackage
import sdu.mdsd.validation.IoTValidator

@ExtendWith(InjectionExtension)
@InjectWith(IoTInjectorProvider)
class ScopingTests {
	@Inject extension ParseHelper<Model>
	@Inject extension ValidationTestHelper
	
	@Test
	def listIdAlreadyInScopeTest(){
		'''
		abstract a {list y }
		controller c : a { list y } 
		'''.parse.assertError(
			IoTPackage.eINSTANCE.pyList, 
			IoTValidator.LIST_EXISTS_IN_SCOPE,
			"List 'y' already defined in scope"
		)
	}
	
	@Test
	def listIdAlreadyInScopeTest2(){
		'''
		abstract a {list y }
		abstract b : a {}
		controller c : b { list y } 
		'''.parse.assertError(
			IoTPackage.eINSTANCE.pyList, 
			IoTValidator.LIST_EXISTS_IN_SCOPE,
			"List 'y' already defined in scope"
		)
	}
	
	@Test
	def validListTest(){
		'''
		abstract a {list y }
		abstract b : a {}
		controller c : b {} 
		'''.parse.assertNoErrors
	}
	
	@Test
	def inheritedSameVariableIdFromMultipleParentsTest(){
		'''
		abstract a { var x }
		abstract b { var x }
		controller c : a, b { var x = 0 } 
		'''.parse.assertError(
			IoTPackage.eINSTANCE.controllerDevice, 
			IoTValidator.CONFILCTING_INHERITANCE,
			"Conflict in inherited variables for 'var x'"
		)
	}
	
	@Test
	def inheritedSameVariableIdFromMultipleParentsTest2(){
		'''
		abstract a { var x }
		abstract aa : a {}
		abstract b { var x }
		controller c : aa, b { var x = 0 } 
		'''.parse.assertError(
			IoTPackage.eINSTANCE.controllerDevice, 
			IoTValidator.CONFILCTING_INHERITANCE,
			"Conflict in inherited variables for 'var x'"
		)
	}
	
	@Test
	def validInheritanceTest(){
		'''
		abstract a {var x1 list y1 }
		abstract b {var x2 list y2 }
		controller c : a, b {var x1 = 5 var x2 = 1} 
		'''.parse.assertNoErrors
	}
}