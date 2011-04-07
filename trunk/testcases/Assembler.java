import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Assembler {
	final static String pInst = "([a-z]+)";
	final static String pLabel = "([\\$]?[_a-zA-Z][_a-zA-Z0-9]*)";
	final static String pReg = "\\$(\\d+|[a-z0-9]+)";
	final static String pImm = "(-?\\d+)";
	final static String pComma = "\\s*,\\s*";
	final static String[] instrPatterns = new String[] {
		// add $rd, $rs, $rt (sub, and, or, slt, sle)
		pInst + "\\s+" + pReg + pComma + pReg + pComma + pReg + "\\s*",
		// sll $rd, $rt, imm (sra, srl)
		"(sll|sra|srl)" + "\\s+" + pReg + pComma + pReg + pComma + pImm + "\\s*",
		// addi $rd, $rt, imm (andi, ori, addiu, subu)
		pInst + "\\s+" + pReg + pComma + pReg + pComma + pImm + "\\s*",
		// lw $rt, imm($rs) (sw)
		pInst + "\\s+" + pReg + pComma + pImm + "\\(" + pReg + "\\)" + "\\s*",
		// beq $rs, $rt, label (bne)
		pInst + "\\s+" + pReg + pComma + pReg + pComma + pLabel + "\\s*",
		// j label (jal)
		"(jal|j)" + "\\s+" + pLabel + "\\s*",
		// jr $reg
		"(jr)" + "\\s+" + pReg + "\\s*",
		// nop (halt, syscall)
		pInst,
		// move $rs, $rt
		pInst + "\\s+" + pReg + pComma + pReg + "\\s*",
		// li $rt, imm
		pInst + "\\s+" + pReg + pComma + pImm + "\\s*",
		// la $rt, label
		pInst + "\\s+" + pReg + pComma + pLabel + "\\s*"
	};

	final static String[] dataPatterns = new String[] {
		// label: .asciiz "%s"
		pLabel + "\\s*:\\s*\\.asciiz\\s*\"(.*)\""
	};

	final static String[] statePatterns = new String[] {
		"\\s*\\.text\\s*",
		"\\s*\\.data\\s*"
	};

	final static String[][] instrList = new String[][] { 
		new String[] { "add", "sub", "and", "or", "slt", "sle" , "jr"}, 
		new String[] { "sll", "srl", "sra", },
		new String[] { "addi", "andi", "ori", "addiu", "subu" }, 
		new String[] { "lw", "sw" },
		new String[] { "beq", "bne", "ble", "bge", "blt", "bgt" },
		new String[] { "j", "jal" }, 
		new String[] { "qqq" },
		new String[] { "nop", "halt", "syscall" },
		new String[] { "move" },
		new String[] { "li" },
		new String[] { "la" }
	};

	final static String[][] opCodeList = new String[][] {
		new String[] { "000000", "000000", "000000", "000000", "000000", "000000" , "000000"},
		new String[] { "000000", "000000", "000000" },
		new String[] { "001000", "001100", "001101", "001000" },
		new String[] { "100011", "101011" },
		new String[] { "000100", "000101" },
		new String[] { "000010", "000011" },
		new String[] { null },
		new String[] { "00000000000000000000000000000000", "11111100000000000000000000000000", null },
		null,
		null,
		new String[] { "001000" }
	};

	final static String[][] funcCodeList = new String[][] { 
		new String[] { "100000", "100010", "100100", "100101", "101010", "100011" , "001000"},
		new String[] { "000000", "000010", "000011" },
	};

	final static String[] regNames = new String[] {
		"zero", "at", "v0", "v1", 
		"a0", "a1", "a2", "a3", 
		"t0", "t1", "t2", "t3", 
		"t4", "t5", "t6", "t7", 
		"s0", "s1", "s2", "s3", 
		"s4", "s5", "s6", "s7", 
		"t8", "t9", "k0", "k1",
		"gp", "sp", "fp", "ra"
	};

	Map<String, Integer> labelMap = new HashMap<String, Integer>();
	Map<String, Integer> dataMap = new HashMap<String, Integer>();
	ArrayList<String> list = new ArrayList<String>();
	ArrayList<String> oriList = new ArrayList<String>();
	ArrayList<String> dataList = new ArrayList<String>();
	ArrayList<String> dataOriList = new ArrayList<String>();
	String tempLabel = "";
	int addr = 0, dataAddr = 0, state = -1, v0Value = -1;

	int findInstr(int kind, String t) throws Exception {
		for (int i = 0; i < instrList[kind].length; ++i)
			if (instrList[kind][i].equals(t)) 
				return i;
		throw new Exception("Invalid instruction " + t);
	}

	String getRegCode(String reg) throws Exception {
		int i;
		try {
			i = Integer.parseInt(reg);
			if (i < 0 || i >= regNames.length)
				throw new Exception("No such registers $" + i);
		}
		catch (NumberFormatException e) {
			for (i = 0; i < regNames.length; ++i) 
				if (regNames[i].equals(reg))
					break;
			if (i == regNames.length) 
				throw new Exception("No such registers $" + reg);
		}
		String res = Integer.toBinaryString(i);
		while (res.length() < 5) res = "0" + res;
		return res;
	}

	String getImmCode(String imm, int d, int u, int bits) throws Exception {
		int i;
		try {
			i = Integer.parseInt(imm);
			if (i > u || i < d)
				throw new Exception("Immediate number " + imm + " out of range");

		}
		catch (NumberFormatException e) { 
			throw new Exception("Invalid immediate number " + imm);
		}

		String res = Integer.toBinaryString(i);
		while (res.length() < bits) res = "0" + res;
		return res.substring(res.length() - bits);
	}

	void matchInstr(String s) throws Exception {
		int a = s.indexOf(":");
		int b = s.indexOf("#");

		String label = a < 0 ? "" : s.substring(0, a);
		String inst = b == -1 ? s.substring(a + 1) : s.substring(a + 1, b - a - 1);

		inst = removeSpace(inst);

		if (!label.equals("") && !Pattern.compile(pLabel).matcher(label).matches()) 
			throw new Exception("Invalid label " + label);

		if (!label.equals("")) {
			if (labelMap.containsKey(label))
				throw new Exception("Duplicate label " + label);
			labelMap.put(label, addr);
		}
		else 
			label = tempLabel;

		tempLabel = "";
		if (inst.equals("")) {
			tempLabel = label;
			return;
		}

		int i;
		Matcher m = null;

		for (i = 0; i < instrPatterns.length; ++i) {
			m = Pattern.compile(instrPatterns[i]).matcher(inst);
			if (m.matches())
				break;
		}
		if (i == instrPatterns.length)
			throw new Exception("Cannot match instruction " + inst);

		//		System.out.println(inst + " " + i);
		int instrIdx = findInstr(i, m.group(1));

		String oriInstr = (label == "" ? "\t" : label + ":") + "\t" + inst;

		switch (i) {
		case 0:
			addInstr(
					opCodeList[i][instrIdx] + 
					getRegCode(m.group(3)) + 
					getRegCode(m.group(4)) + 
					getRegCode(m.group(2)) +
					"00000" +
					funcCodeList[i][instrIdx],
					oriInstr);
			break;

		case 1:
			addInstr(
					opCodeList[i][instrIdx] +
					getRegCode(m.group(3)) +
					"00000" + 
					getRegCode(m.group(2)) + 
					getImmCode(m.group(4), 0, 31, 5) + 
					funcCodeList[i][instrIdx],
					oriInstr);
			break;

		case 2:
			if (instrIdx == 4) {
				tempLabel = label;
				matchInstr("addiu $" + m.group(2) + ", $" + m.group(3) + ", " + (-Integer.parseInt(m.group(4))));
			}
			else 
				addInstr(
						opCodeList[i][instrIdx] +
						getRegCode(m.group(3)) +
						getRegCode(m.group(2)) +
						getImmCode(m.group(4), Integer.MIN_VALUE, Integer.MAX_VALUE, 16),
						oriInstr);
			break;

		case 3:
			addInstr(
					opCodeList[i][instrIdx] +
					getRegCode(m.group(4)) +
					getRegCode(m.group(2)) +
					getImmCode(m.group(3), Integer.MIN_VALUE, Integer.MAX_VALUE, 16),
					oriInstr);
			break;

		case 4:
			if (instrIdx >= opCodeList[i].length) {
				String binst = instrList[i][instrIdx];
				String rs = m.group(2), rt = m.group(3);
				if (binst.indexOf('g') != -1) {
					String temp = rs;
					rs = rt;
					rt = temp;
				}
				tempLabel = label;
				matchInstr("sl" + binst.charAt(binst.length() - 1) + " $at, $" + rs + ", $" + rt);
				matchInstr("bne $at, $0, " + m.group(4));
			}
			else {
				addInstr(
						opCodeList[i][instrIdx] +
						getRegCode(m.group(2)) +
						getRegCode(m.group(3)) +
						"?b(" + m.group(4) + ")",
						oriInstr);
				matchInstr("nop");
			}
			break;

		case 5:
			addInstr(
					opCodeList[i][instrIdx] +
					"?j(" + m.group(2) + ")",
					oriInstr);
			matchInstr("nop");
			break;

		case 6:
			addInstr(
					opCodeList[i][instrIdx] +
					getRegCode(m.group(2)) + "00000" +
					"0000000000000000",
					oriInstr);
			matchInstr("nop");
			break;

		case 7:
			if (instrIdx == 2) {
				tempLabel = label;
				if (v0Value == -1)
					throw new Exception("Undetermint $v0 value");
				else if (v0Value == 1)
					matchInstr("sw $a0, -4($0)");
				else if (v0Value == 4)
					matchInstr("sw $a0, -8($0)");
				else
					throw new Exception("Unknown syscall for $v0 = " + v0Value);
				break;
			}
			if (instrIdx == 1)
				for (int j = 0; j < 4; ++j)
					addInstr(opCodeList[i][0], "\t\tnop");
			addInstr(opCodeList[i][instrIdx], oriInstr);
			break;

		case 8:
			tempLabel = label;
			matchInstr("add " + "$" + m.group(2) + ", " + "$" + m.group(3) + ", $0");
			break;

		case 9:
			if (m.group(2).equals("v0"))
				v0Value = Integer.parseInt(m.group(3));
			tempLabel = label;
			matchInstr("addi " + "$" + m.group(2) + ", $0, " + m.group(3));
			break;

		case 10:
			addInstr(
					opCodeList[i][instrIdx] + 
					getRegCode("0") +
					getRegCode(m.group(2)) +
					"?d(" + m.group(3) + ")",
					oriInstr);
			break;					

		default:
			throw new Exception("Fatal, unknown type of instruction");
		}
	}

	void addInstr(String bin, String ori) {
		list.add(bin);
		oriList.add(ori);
		addr++;
	}

	static String removeSpace(String s) {
		int i, j;
		for (i = 0; i < s.length(); ++i) 
			if (!(s.charAt(i) == '\t' || s.charAt(i) == ' '))
				break;
		for (j = s.length()-1; j >= 0; --j)  
			if (!(s.charAt(j) == '\t' || s.charAt(j) == ' '))
				break;
		if (i > j) return "";
		return s.substring(i, j + 1);
	}

	void backpatch() throws Exception {
		for (int i = 0; i < list.size(); ++i) {
			String inst = list.get(i);
			if (inst.endsWith(")")) {
				String gLabel = inst.substring(inst.indexOf("(") + 1, inst.length() - 1);
				char kind = inst.charAt(inst.indexOf("?") + 1);
				inst = inst.substring(0, inst.indexOf("?"));

				int addr;
				switch (kind) {
				case 'j':
				case 'b':
					if (!labelMap.containsKey(gLabel))
						throw new Exception("No such label " + gLabel);
					addr = labelMap.get(gLabel);
					if (kind == 'j')
						inst += getImmCode(Integer.toString(addr), Integer.MIN_VALUE, Integer.MAX_VALUE, 26);
					else
						inst += getImmCode(Integer.toString(addr - (i + 1)), Integer.MIN_VALUE, Integer.MAX_VALUE, 16);
					break;
				case 'd':
					if (!dataMap.containsKey(gLabel))
						throw new Exception("No such data label " + gLabel);
					addr = dataMap.get(gLabel);
					inst += getImmCode(Integer.toString(addr), Integer.MIN_VALUE, Integer.MAX_VALUE, 16);
					break;
				default:
					throw new Exception("Fatal, unknown backpatch type");
				}

				list.set(i, inst);
			}
		}
	}

	void matchData(String s) throws Exception {
		Matcher m = null;
		for (int i = 0; i < dataPatterns.length; ++i) { 
			m = Pattern.compile(dataPatterns[i], Pattern.DOTALL).matcher(s);
			if (m.matches()) {
				String label = m.group(1), data = m.group(2) + '\u0000';
				dataMap.put(label, dataAddr);

				String ndata = data.replaceFirst("\\\\n", new String(new char[] { 13 }));

				for (int j = 0; j < ndata.length(); ++j) {
					dataList.add(Integer.toBinaryString((int)ndata.charAt(j)));
					if (j == 0)
						dataOriList.add(data);
					else
						dataOriList.add("");
				}

				dataAddr += ndata.length();
				return;
			}
		}

		throw new Exception("Unrecoginzed data format <" + s + ">");
	}

	void matchState(String s) throws Exception {
		for (int i = 0; i < statePatterns.length; ++i)
			if (Pattern.compile(statePatterns[i]).matcher(s).matches()) {
				state = i;
				return;
			}
		if (state == -1)
			throw new Exception("Is this statement \"" + s + "\" a data or an instruction?");
		else if (state == 0)
			matchInstr(s);
		else
			matchData(s);
	}

	void writeToFile(String fn, ArrayList<String> list, ArrayList<String> oriList) throws FileNotFoundException {
		PrintWriter pWriter = new PrintWriter(fn);
//		pWriter.println("DEPTH = " + (list.size() + 4) + ";");
//		pWriter.println("WIDTH = 32;\n");

//		pWriter.println("ADDRESS_RADIX = HEX;");
//		pWriter.println("DATA_RADIX = HEX;\n");

//		pWriter.println("CONTENT\nBEGIN");

		for (int i = 0; i < list.size(); ++i) {
			String s = Long.toHexString(Long.parseLong(list.get(i), 2)).toUpperCase();
			while (s.length() < 8) s = "0" + s;

			s = Long.toHexString(i).toUpperCase() + "\t" + s;
			s += "//\t\t" + list.get(i) + "\t\t" + oriList.get(i);

			pWriter.println("@" + s);
		}

//		pWriter.println("END;");
		pWriter.close();

		System.out.println("Succeeded");
	}

	public Assembler(String fn, String ofn) throws FileNotFoundException, IOException {
		System.out.println("Assembler for MIPS32 CPU by lqhl");

		try {
			BufferedReader bReader = new BufferedReader(new InputStreamReader(new FileInputStream(fn)));
			
			System.out.println("Analyzing source file \"" + fn + "\"");

			String s;
			int line = 0;
			try {
				matchInstr("jal main");
				matchInstr("halt");
				while ((s = bReader.readLine()) != null) {
					line++;
					s = removeSpace(s);
					if (s.equals("")) continue;
					matchState(s);
				}
				backpatch();
			}
			catch (Exception e) {
				System.out.println(e.getMessage());
				System.out.println("Fail to analyze at line " + line);
				//e.printStackTrace();
				return;
			}
			bReader.close();

			System.out.print("Writing to instruction mif file \"" + ofn + "\"...  ");
			writeToFile(ofn, list, oriList);
			System.out.println();

		}
		catch (FileNotFoundException e) {
			System.out.println(e.getMessage());
			System.out.println();
			System.exit(1);
		}
	}

	public static void main(String[] args) throws IOException {
		if (args.length < 2) {
			System.out.println("Usage: java Assembler <.s filename> <instruction mif filename>");
			System.exit(1);
		}
		new Assembler(args[0], args[1]);
	}
}
